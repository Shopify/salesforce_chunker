require "test_helper"

class SalesforceChunkerTest < Minitest::Test

  def setup
    SalesforceChunker::Connection.stubs(:new)
    @bulk_client = SalesforceChunker::Client.new({})
    @rest_client = SalesforceChunker::Client.new({}, bulk=false)
    SalesforceChunker::Connection.unstub(:new)
  end

  def test_that_it_has_a_version_number
    refute_nil ::SalesforceChunker::VERSION
  end

  def test_initialize_rest_api
    SalesforceChunker::Connection::RestApi.expects(:new)
    SalesforceChunker::Client.new({}, bulk=false)
  end

  def test_raise_error_when_no_block_given_in_query
    assert_raises StandardError do
      @bulk_client.query("", "")
    end
  end

  def test_rest_query_raises_response_error
    connection = mock()
    connection.expects(:version).returns("41.0")
    connection.expects(:get_json).with("/services/data/v41.0/query/?q=SELECT Id FROM Object WHERE CreatedAt >= 2016-01-01T00:00:00%2B00:00").returns(invalid_json_response)
    @rest_client.instance_variable_set(:@connection, connection)

    assert_raises SalesforceChunker::ResponseError do
      @rest_client.query(soql_query, "") do |result|
        yield(result)
      end
    end
  end

  def test_rest_query_yields_paginated_results
    connection = mock()
    connection.expects(:version).returns("41.0")
    connection.expects(:get_json).twice.returns(first_json_response, second_json_response)
    @rest_client.instance_variable_set(:@connection, connection)

    actual_results = []
    expected_results = [
      {
        "attributes" => {
          "type" => "Object",
          "url"  => "/services/data/v41.0/sobjects/Object/something"
        },
        "Id" => "object1"
      },
      {
        "attributes" => {
          "type" => "Object",
          "url"  => "/services/data/v41.0/sobjects/Object/something"
        },
        "Id" => "object2"
      },
      {
        "attributes" => {
          "type" => "Object",
          "url"  => "/services/data/v41.0/sobjects/Object/something"
        },
        "Id" => "object3"
      }
    ]

    @rest_client.query(soql_query, "") { |result| actual_results << result }
    assert_equal expected_results, actual_results
  end

  def test_bulk_query_raise_timeout_error_when_query_exceeds_timeout_seconds
    job = mock()
    job.expects(:get_batch_statuses).at_least_once.returns([
      {"id" => "55024000002iETSAA2", "state" => "Queued"},
    ])
    job.expects(:batches_count).at_least_once.returns(1)

    SalesforceChunker::Job.stubs(:new).returns(job)
    assert_raises SalesforceChunker::TimeoutError do
      @bulk_client.query("", "", retry_seconds: 0, timeout_seconds: 0) do |result|
        yield(result)
      end
    end
  end

  def test_bulk_query_raise_record_error_when_batch_completes_with_failed_records
    job = mock()
    job.expects(:get_batch_statuses).returns([
      {"id" => "55024000002iETSAA2", "state" => "NotProcessed"},
      {"id" => "55024000002iETTAA2", "state" => "InProgress"},
      {"id" => "55024000002iETUAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 0},
      {"id" => "55024000002iETVAA2", "state" => "Completed", "numberRecordsFailed" => 1, "numberRecordsProcessed" => 0},
    ])
    job.expects(:batches_count).returns(3)

    SalesforceChunker::Job.stubs(:new).returns(job)
    assert_raises SalesforceChunker::RecordError do
      @bulk_client.query("", "") do |result|
        yield(result)
      end
    end
  end

  def test_bulk_query_raise_batch_error_when_batch_fails_to_process
    job = mock()
    job.expects(:get_batch_statuses).returns([
      {"id" => "55024000002iETSAA2", "state" => "NotProcessed"},
      {"id" => "55024000002iETTAA2", "state" => "InProgress"},
      {"id" => "55024000002iETVAA2", "state" => "Failed", "stateMessage" => "Incorrect format"},
    ])
    job.expects(:batches_count).never

    SalesforceChunker::Job.stubs(:new).returns(job)
    assert_raises SalesforceChunker::BatchError do
      @bulk_client.query("", "") do |result|
        yield(result)
      end
    end
  end

  def test_bulk_query_yields_batch_results
    job = mock()

    first_batch_status = [
      {"id" => "55024000002iETSAA2", "state" => "NotProcessed"},
      {"id" => "55024000002iETTAA2", "state" => "InProgress"},
      {"id" => "55024000002iETUAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 3},
    ]

    second_batch_status = [
      {"id" => "55024000002iETSAA2", "state" => "NotProcessed"},
      {"id" => "55024000002iETTAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 1},
      {"id" => "55024000002iETUAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 3},
    ]

    job.expects(:get_batch_statuses).twice.returns(first_batch_status, second_batch_status)

    job.expects(:get_batch_results).with("55024000002iETUAA2").multiple_yields(
      [{"CustomColumn__c" => "abc"}],
      [{"CustomColumn__c" => "def"}],
      [{"CustomColumn__c" => "ghi"}],
    )

    job.expects(:get_batch_results).with("55024000002iETTAA2").yields(
      {"CustomColumn__c" => "jkl"},
    )

    job.expects(:batches_count).times(6).returns(2)

    actual_results = []
    expected_results = [
      {"CustomColumn__c" => "abc"},
      {"CustomColumn__c" => "def"},
      {"CustomColumn__c" => "ghi"},
      {"CustomColumn__c" => "jkl"},
    ]

    SalesforceChunker::Job.stubs(:new).returns(job)
    @bulk_client.query("", "", retry_seconds: 0) { |result| actual_results << result }
    assert_equal expected_results, actual_results
  end

  private

  def soql_query
    <<~SOQL
      SELECT Id FROM Object
      WHERE CreatedAt >= 2016-01-01T00:00:00+00:00
    SOQL
  end

  def first_json_response
    {
      "totalSize" => 3,
      "done" => false,
      "nextRecordsUrl" => "/services/data/v41.0/query/nextpage",
      "records" => [
        {
          "attributes" => {
            "type" => "Object",
            "url"  => "/services/data/v41.0/sobjects/Object/something"
          },
          "Id" => "object1"
        },
        {
          "attributes" => {
            "type" => "Object",
            "url"  => "/services/data/v41.0/sobjects/Object/something"
          },
          "Id" => "object2"
        }
      ]
    }
  end

  def second_json_response
    {
      "totalSize" => 3,
      "done" => true,
      "records" => [
        {
          "attributes" => {
            "type" => "Object",
            "url"  => "/services/data/v41.0/sobjects/Object/something"
          },
          "Id" => "object3"
        }
      ]
    }
  end

  def invalid_json_response
    [
      {
        "errorCode" => "invalid_query",
        "message"   => "error in query"
      }
    ]
  end
end
