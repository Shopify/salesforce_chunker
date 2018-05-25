require "test_helper"

class SalesforceChunkerTest < Minitest::Test

  def setup
    SalesforceChunker::Connection.stubs(:new)
    @client = SalesforceChunker::Client.new({})
    SalesforceChunker::Connection.unstub(:new)
  end

  def test_that_it_has_a_version_number
    refute_nil ::SalesforceChunker::VERSION
  end

  def test_raise_error_when_no_block_given_in_query
    assert_raises StandardError do
      @client.query("", "")
    end
  end

  def test_raise_timeout_error_when_query_exceeds_timeout_seconds
    job = mock()
    job.expects(:get_batch_statuses).at_least_once.returns([
      {"id" => "55024000002iETSAA2", "state" => "Queued"},
    ])
    job.expects(:batches_count).at_least_once.returns(1)

    SalesforceChunker::Job.stubs(:new).returns(job)
    assert_raises SalesforceChunker::TimeoutError do
      @client.query("", "", retry_seconds: 1, timeout_seconds: 1) do |result|
        yield(result)
      end
    end
  end

  def test_raise_record_error_when_batch_completes_with_failed_records
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
      @client.query("", "") do |result|
        yield(result)
      end
    end
  end

  def test_raise_batch_error_when_batch_fails_to_process
    job = mock()
    job.expects(:get_batch_statuses).returns([
      {"id" => "55024000002iETSAA2", "state" => "NotProcessed"},
      {"id" => "55024000002iETTAA2", "state" => "InProgress"},
      {"id" => "55024000002iETVAA2", "state" => "Failed", "stateMessage" => "Incorrect format"},
    ])
    job.expects(:batches_count).never

    SalesforceChunker::Job.stubs(:new).returns(job)
    assert_raises SalesforceChunker::BatchError do
      @client.query("", "") do |result|
        yield(result)
      end
    end
  end

  def test_query_yields_batch_results
    job = mock()

    # Retrieve second round of batches
    job.expects(:get_batch_statuses).returns([
      {"id" => "55024000002iETSAA2", "state" => "NotProcessed"},
      {"id" => "55024000002iETTAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 1},
      {"id" => "55024000002iETUAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 3},
    ])
    job.expects(:get_batch_results).with("55024000002iETTAA2").yields(
      {"CustomColumn__c" => "jkl"},
    )

    # Retrieve first round of batches
    job.expects(:get_batch_statuses).returns([
      {"id" => "55024000002iETSAA2", "state" => "NotProcessed"},
      {"id" => "55024000002iETTAA2", "state" => "InProgress"},
      {"id" => "55024000002iETUAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 3},
    ])
    job.expects(:get_batch_results).with("55024000002iETUAA2").multiple_yields(
      [{"CustomColumn__c" => "abc"}],
      [{"CustomColumn__c" => "def"}],
      [{"CustomColumn__c" => "ghi"}],
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
    @client.query("", "", retry_seconds: 1) { |result| actual_results << result }
    assert_equal expected_results, actual_results
  end
end
