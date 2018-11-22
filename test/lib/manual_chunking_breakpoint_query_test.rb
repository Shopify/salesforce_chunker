require "test_helper"

class ManualChunkingBreakpointQueryTest < Minitest::Test

  def setup
    SalesforceChunker::ManualChunkingBreakpointQuery.any_instance.stubs(:create_job)
    SalesforceChunker::ManualChunkingBreakpointQuery.any_instance.stubs(:create_batch)
    SalesforceChunker::ManualChunkingBreakpointQuery.any_instance.stubs(:close)
    @job = SalesforceChunker::ManualChunkingBreakpointQuery.new(connection: nil, object: nil, operation: "query", query: "")
    SalesforceChunker::ManualChunkingBreakpointQuery.any_instance.unstub(:create_job)
    SalesforceChunker::ManualChunkingBreakpointQuery.any_instance.unstub(:create_batch)
    SalesforceChunker::ManualChunkingBreakpointQuery.any_instance.unstub(:close)
    @job.instance_variable_set(:@job_id, "3811P00000EFQiYQAX")
  end

  def test_initialize
    SalesforceChunker::ManualChunkingBreakpointQuery.any_instance.expects(:create_job)
      .with("CustomObject__c", {})
      .returns("3811P00000EFQiYQAB")

    SalesforceChunker::ManualChunkingBreakpointQuery.any_instance.expects(:create_batch)
      .with("Select Id From CustomObject__c Order By Id Asc")
      .returns("3811P00000EFQidQAX")

    SalesforceChunker::ManualChunkingBreakpointQuery.any_instance.expects(:close)

    job = SalesforceChunker::ManualChunkingBreakpointQuery.new(
      connection: "connect",
      object: "CustomObject__c",
      operation: "query",
    )

    assert_equal 100000, job.instance_variable_get(:@batch_size)
    assert_equal 1, job.instance_variable_get(:@batches_count)
    assert_equal "connect", job.instance_variable_get(:@connection)
    assert_equal "query", job.instance_variable_get(:@operation)
    assert_equal "3811P00000EFQiYQAB", job.instance_variable_get(:@job_id)
  end

  def test_get_batch_results
    @job.expects(:retrieve_batch_results).with("55024000002iETSAA2").returns([
      "6502E000002iETSAA3",
      "6502E000002jETSAA3",
    ])
    @job.expects(:retrieve_raw_results).with("55024000002iETSAA2", "6502E000002iETSAA3").returns(
      "\"Id\"\n\"55024000002iETSAA3\"\n\"55024000002iETTAA3\"\n\"55024000002iETUAA3\"\n\"55024000002iETVAA3\"\n"
    )
    @job.expects(:retrieve_raw_results).with("55024000002iETSAA2", "6502E000002jETSAA3").returns(
      "\"Id\"\n\"55024000002iETaAA3\"\n\"55024000002iETbAA3\"\n\"55024000002iETcAA3\"\n\"55024000002iETdAA3\"\n"
    )

    @job.expects(:process_csv_results)
      .with("\"Id\"\n\"55024000002iETSAA3\"\n\"55024000002iETTAA3\"\n\"55024000002iETUAA3\"\n\"55024000002iETVAA3\"\n")
      .yields("55024000002iETaAA3")

    @job.expects(:process_csv_results)
      .with("\"Id\"\n\"55024000002iETaAA3\"\n\"55024000002iETbAA3\"\n\"55024000002iETcAA3\"\n\"55024000002iETdAA3\"\n")
      .yields("55024000002iETcAA3")

    actual_results = []
    @job.get_batch_results("55024000002iETSAA2") { |result| actual_results.push(result) }

    assert_equal ["55024000002iETaAA3", "55024000002iETcAA3"], actual_results
  end

  def test_process_csv_results_smaller_or_equal_to_batch_size_returns_empty
    csv_string = "\"Id\"\n\"55024000002iETSAA3\"\n\"55024000002iETTAA3\"\n"
    @job.instance_variable_set(:@batch_size, 2)

    actual_results = []
    @job.process_csv_results(csv_string) { |result| actual_results.push(result) }

    assert_empty actual_results
  end

  def test_process_csv_results_returns_first_after_batch_size
    csv_string = "\"Id\"\n\"55024000002iETSAA3\"\n\"55024000002iETTAA3\"\n\"55024000002iETUAA3\"\n"
    @job.instance_variable_set(:@batch_size, 2)

    actual_results = []
    @job.process_csv_results(csv_string) { |result| actual_results.push(result) }

    assert_equal ["55024000002iETUAA3"], actual_results
  end

  def test_process_csv_results_returns_multiple
    csv_string = "\"Id\"\n\"55024000002iETSAA3\"\n\"55024000002iETTAA3\"\n\"55024000002iETUAA3\"\n\"55024000002iETVAA3\"\n\"55024000002iETWAA3\"\n"
    @job.instance_variable_set(:@batch_size, 2)

    actual_results = []
    @job.process_csv_results(csv_string) { |result| actual_results.push(result) }

    assert_equal ["55024000002iETUAA3", "55024000002iETWAA3"], actual_results
  end

  def test_create_batch
    connection = mock()
    connection.expects(:post).with(
      "job/3811P00000EFQiYQAX/batch",
      "Select Id From Object__c",
      {"Content-Type": "text/csv"}
    ).returns({"batchInfo" => 
      {"id"=> "55024000002iETSAA2", "state"=> "Queued"},
    })

    @job.instance_variable_set(:@connection, connection)

    assert_equal "55024000002iETSAA2", @job.create_batch("Select Id From Object__c")
  end

  def test_retrieve_batch_results_array
    SalesforceChunker::Job.any_instance.expects(:retrieve_batch_results).with("55024000002iETSAA2").returns({
      "result_list" => 
      { 
        "result" => 
        [
          "3811P00000EFQiaQAX",
          "3811P00000EFQibQAX",
          "3811P00000EFQicQAX",
        ]
      }
    })

    expected = ["3811P00000EFQiaQAX", "3811P00000EFQibQAX", "3811P00000EFQicQAX"]

    assert_equal expected, @job.retrieve_batch_results("55024000002iETSAA2")
  end

  def test_retrieve_batch_results_single_response
    SalesforceChunker::Job.any_instance.expects(:retrieve_batch_results).with("55024000002iETSAA2").returns({
      "result_list" =>
      {
        "result" => "3811P00000EFQiaQAX"
      }
    })

    expected = ["3811P00000EFQiaQAX"]

    assert_equal expected, @job.retrieve_batch_results("55024000002iETSAA2")
  end

  def test_get_batch_statuses
    connection = mock()
    connection.expects(:get_json).with(
      "job/3811P00000EFQiYQAX/batch",
    ).returns({"batchInfoList" =>
      {
        "batchInfo" => {"id"=> "55024000002iETSAA2", "state"=> "Queued"},
      },
    })

    @job.instance_variable_set(:@connection, connection)

    assert_equal [{"id"=> "55024000002iETSAA2", "state"=> "Queued"}], @job.get_batch_statuses
  end

  def test_create_job_uses_csv_content_type
    SalesforceChunker::Job.any_instance.expects(:create_job).with("Object__c", {content_type: "CSV"})
      .returns("3811P00000YYQiYQAX")

    assert_equal "3811P00000YYQiYQAX", @job.create_job("Object__c", {})
  end
end
