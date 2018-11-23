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


end
