require "test_helper"

class JobTest < Minitest::Test

  def setup
    SalesforceChunker::Job.any_instance.stubs(:create_job)
    @job = SalesforceChunker::Job.new(connection: nil, object: nil, operation: nil)
    SalesforceChunker::Job.any_instance.unstub(:create_job)
    @job.instance_variable_set(:@job_id, "3811P00000EFQiYQAX")
  end

  def test_initialize_creates_job
    SalesforceChunker::Job.any_instance.expects(:create_job)
      .with("CustomObject__c", {})
      .returns("3811P00000EFQiYQAZ")

    job = SalesforceChunker::Job.new(
      connection: "connect",
      object: "CustomObject__c",
      operation: "query",
      query: "Select CustomColumn__c From CustomObject__c",
    )

    assert_equal "connect", job.instance_variable_get(:@connection)
    assert_equal "query", job.instance_variable_get(:@operation)
    assert_equal "3811P00000EFQiYQAZ", job.instance_variable_get(:@job_id)
  end

  def test_get_batch_statuses_returns_batches
    connection = mock()
    connection.expects(:get_json).with(
      "job/3811P00000EFQiYQAX/batch",
    ).returns({"batchInfo" => [
      {"id"=> "55024000002iETSAA2", "state"=> "Completed"},
      {"id"=> "55024000002iETTAA2", "state"=> "InProgress"},
    ]})
    @job.instance_variable_set(:@connection, connection)

    assert_equal 2, @job.get_batch_statuses.size
  end

  def test_get_batch_results_retrieves_all_results
    @job.expects(:retrieve_batch_results).with("55024000002iETSAA2").returns([
      "6502E000002iETSAA3",
      "6502E000002jETSAA3",
    ])
    @job.expects(:retrieve_results).with("55024000002iETSAA2", "6502E000002iETSAA3").returns([
      {"CustomColumn__c" => "abc", "attributes" => "blah"},
      {"CustomColumn__c" => "def", "attributes" => "blah"},
    ])
    @job.expects(:retrieve_results).with("55024000002iETSAA2", "6502E000002jETSAA3").returns([
      {"CustomColumn__c" => "ghi", "attributes" => "blah"},
      {"CustomColumn__c" => "jkl", "attributes" => "blah"},
    ])

    actual_results = []
    @job.get_batch_results("55024000002iETSAA2") { |result| actual_results.append(result) }

    expected_results = [
      {"CustomColumn__c" => "abc"},
      {"CustomColumn__c" => "def"},
      {"CustomColumn__c" => "ghi"},
      {"CustomColumn__c" => "jkl"},
    ]
    assert_equal expected_results, actual_results
  end

  def test_create_job_sends_request
    connection = mock()
    connection.expects(:post_json).with(
      "job",
      {"operation": "query", "object": "CustomObject__c", "contentType": "JSON"},
      {"foo": "bar"},
    ).returns({
      "id" => "3811P00000EFQiYQAX"
    })
    @job.instance_variable_set(:@connection, connection)
    @job.instance_variable_set(:@operation, "query")

    @job.send(:create_job, "CustomObject__c", {"headers": {"foo": "bar"}})
  end

  def test_create_job_uses_external_id
    connection = mock()
    connection.expects(:post_json).with(
      "job",
      {"operation": "upsert", "object": "CustomObject__c", "contentType": "JSON", "externalIdFieldName": "Field__c"},
      {},
    ).returns({
      "id" => "3811P00000EFQiYQAX"
    })
    @job.instance_variable_set(:@connection, connection)
    @job.instance_variable_set(:@operation, "upsert")

    @job.send(:create_job, "CustomObject__c", {"external_id": "Field__c"})
  end

  def test_create_batch_sends_query_as_string
    connection = mock()
    connection.expects(:post).with(
      "job/3811P00000EFQiYQAX/batch", 
      "Select CustomColumn__c From CustomObject__c",
    ).returns({
      "id" => "55024000002iETSAA2"
    })
    @job.instance_variable_set(:@connection, connection)
    @job.instance_variable_set(:@operation, "query")

    @job.create_batch("Select CustomColumn__c From CustomObject__c")
  end

  def test_create_batch_sends_json
    connection = mock()
    connection.expects(:post_json).with(
      "job/3811P00000EFQiYQAX/batch",
      {"name": "bar.myshopify.com"},
    ).returns({
      "id" => "55024000002iETSAA3"
    })
    @job.instance_variable_set(:@connection, connection)
    @job.instance_variable_set(:@operation, "insert")

    @job.create_batch({"name": "bar.myshopify.com"})
  end

  def test_retrieve_batch_results_returns_information
    connection = mock()
    connection.expects(:get_json).with(
      "job/3811P00000EFQiYQAX/batch/55024000002iETSAA2/result",
    ).returns([
      "6502E000002iETSAA3",
      "6502E000002jETSAA3",
    ])
    @job.instance_variable_set(:@connection, connection)

    assert_equal ["6502E000002iETSAA3", "6502E000002jETSAA3"], @job.retrieve_batch_results("55024000002iETSAA2")
  end

  def test_retrieve_results_returns_information
    connection = mock()
    connection.expects(:get_json).with(
      "job/3811P00000EFQiYQAX/batch/55024000002iETSAA2/result/6502E000002iETSAA3",
    ).returns([
      {CustomColumn__c: "abc"},
    ])
    @job.instance_variable_set(:@connection, connection)

    assert_equal [{CustomColumn__c: "abc"}], @job.retrieve_results("55024000002iETSAA2", "6502E000002iETSAA3")
  end

  def test_close_posts_json
    connection = mock()
    connection.expects(:post_json).with(
      "job/3811P00000EFQiYQAX/",
      {"state": "Closed"},
    ).returns([])
    @job.instance_variable_set(:@connection, connection)

    @job.close
  end

  def test_get_completed_batches_raises_record_error_on_failed_records
    @job.expects(:get_batch_statuses).returns([
      {"id" => "55024000002iETSAA2", "state" => "NotProcessed"},
      {"id" => "55024000002iETTAA2", "state" => "InProgress"},
      {"id" => "55024000002iETUAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 0},
      {"id" => "55024000002iETVAA2", "state" => "Completed", "numberRecordsFailed" => 1, "numberRecordsProcessed" => 0},
    ])

    assert_raises SalesforceChunker::RecordError do
      @job.get_completed_batches
    end
  end

  def test_get_completed_batches_raises_batch_error_on_failed_batch
    @job.expects(:get_batch_statuses).returns([
      {"id" => "55024000002iETSAA2", "state" => "NotProcessed"},
      {"id" => "55024000002iETTAA2", "state" => "InProgress"},
      {"id" => "55024000002iETVAA2", "state" => "Failed", "stateMessage" => "Incorrect format"},
    ])

    assert_raises SalesforceChunker::BatchError do
      @job.get_completed_batches
    end
  end

  def test_get_completed_batches_returns_completed_batches
    @job.expects(:get_batch_statuses).returns([
      {"id" => "55024000002iETSAA2", "state" => "NotProcessed"},
      {"id" => "55024000002iETTAA2", "state" => "InProgress"},
      {"id" => "55024000002iETUAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 3},
    ])

    expected = [{"id" => "55024000002iETUAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 3}]
    assert_equal expected, @job.get_completed_batches
  end

  def test_raise_timeout_error_when_batch_completion_exceeds_timeout
    @job.expects(:get_completed_batches).at_least_once.returns([])
    @job.instance_variable_set(:@batches_count, 1)
    @job.instance_variable_set(:@operation, "query")

    assert_raises SalesforceChunker::TimeoutError do
      @job.download_results(retry_seconds: 0, timeout_seconds: 0) do |result|
        yield(result)
      end
    end
  end

  def test_download_results
    first_completed_batches = [
      {"id" => "55024000002iETUAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 3},
    ]

    second_completed_batches = [
      {"id" => "55024000002iETTAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 1},
      {"id" => "55024000002iETUAA2", "state" => "Completed", "numberRecordsFailed" => 0, "numberRecordsProcessed" => 3},
    ]

    @job.expects(:get_completed_batches).twice.returns(first_completed_batches, second_completed_batches)

    @job.expects(:get_batch_results).with("55024000002iETUAA2").multiple_yields(
      [{"CustomColumn__c" => "abc"}],
      [{"CustomColumn__c" => "def"}],
      [{"CustomColumn__c" => "ghi"}],
    )

    @job.expects(:get_batch_results).with("55024000002iETTAA2").yields(
      {"CustomColumn__c" => "jkl"},
    )

    @job.instance_variable_set(:@batches_count, 2)
    @job.instance_variable_set(:@operation, "query")

    actual_results = []
    expected_results = [
      {"CustomColumn__c" => "abc"},
      {"CustomColumn__c" => "def"},
      {"CustomColumn__c" => "ghi"},
      {"CustomColumn__c" => "jkl"},
    ]

    @job.expects(:sleep).with(7).once

    @job.download_results(retry_seconds: 7) do |result|
      actual_results << result
    end

    assert_equal expected_results, actual_results
  end
end
