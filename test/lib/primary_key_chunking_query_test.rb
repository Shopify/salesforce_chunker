require "test_helper"

class PrimaryKeyChunkingQueryTest < Minitest::Test

  def setup
    SalesforceChunker::PrimaryKeyChunkingQuery.any_instance.stubs(:create_job)
    SalesforceChunker::PrimaryKeyChunkingQuery.any_instance.stubs(:create_batch)
    @job = SalesforceChunker::PrimaryKeyChunkingQuery.new(connection: nil, object: nil, operation: nil, query: nil)
    SalesforceChunker::PrimaryKeyChunkingQuery.any_instance.unstub(:create_job)
    SalesforceChunker::PrimaryKeyChunkingQuery.any_instance.unstub(:create_batch)
    @job.instance_variable_set(:@job_id, "3811P00000EFQiYQAX")
  end

  def test_initialize_creates_job_and_batch
    SalesforceChunker::Job.any_instance.expects(:create_job)
      .with("CustomObject__c", { headers: { "Sforce-Enable-PKChunking": "true; chunkSize=4300;" }})
      .returns("3811P00000EFQiYQAZ")
    SalesforceChunker::Job.any_instance.expects(:create_batch)
      .with("Select CustomColumn__c From CustomObject__c")
      .returns("55024000002iETSAA2")

    job = SalesforceChunker::PrimaryKeyChunkingQuery.new(
      connection: "connect",
      object: "CustomObject__c",
      operation: "query",
      query: "Select CustomColumn__c From CustomObject__c",
      batch_size: 4300,
    )

    assert_equal "connect", job.instance_variable_get(:@connection)
    assert_equal "query", job.instance_variable_get(:@operation)
    assert_equal "55024000002iETSAA2", job.instance_variable_get(:@initial_batch_id)
    assert_equal "3811P00000EFQiYQAZ", job.instance_variable_get(:@job_id)
  end


  def test_get_batch_status_calls_finalize_chunking_setup_when_batches_count_is_nil
    connection = mock()
    connection.expects(:get_json).with(
      "/job/3811P00000EFQiYQAX/batch",
    ).returns({"batchInfo" => [
      {"id"=> "55024000002iETSAA2", "state"=> "Completed"},
      {"id"=> "55024000002iETTAA2", "state"=> "InProgress"},
    ]})
    @job.instance_variable_set(:@connection, connection)
    @job.instance_variable_set(:@batches_count, nil)
    @job.expects(:finalize_chunking_setup)

    @job.get_batch_statuses
  end

  def test_get_batch_status_doesnt_call_finalize_chunking_setup_when_batches_count_is_not_nil
    connection = mock()
    connection.expects(:get_json).with(
      "/job/3811P00000EFQiYQAX/batch",
    ).returns({"batchInfo" => [
      {"id"=> "55024000002iETSAA2", "state"=> "NotProcessed"},
      {"id"=> "55024000002iETTAA2", "state"=> "InProgress"},
      {"id"=> "55024000002iETUAA2", "state"=> "InProgress"},
      {"id"=> "55024000002iETVAA2", "state"=> "Completed"},
    ]})
    @job.instance_variable_set(:@connection, connection)
    @job.instance_variable_set(:@batches_count, 3)
    @job.expects(:finalize_chunking_setup).never

    @job.get_batch_statuses
  end

  def test_finalize_chunking_setup_sets_batches_count_and_closes_once_initial_batch_is_ready
    batches = [
      {"id"=> "55024000002iETSAA2", "state"=> "NotProcessed"},
      {"id"=> "55024000002iETTAA2", "state"=> "InProgress"},
      {"id"=> "55024000002iETUAA2", "state"=> "InProgress"},
      {"id"=> "55024000002iETVAA2", "state"=> "Completed"},
    ]
    @job.instance_variable_set(:@initial_batch_id, "55024000002iETSAA2")
    @job.expects(:close)

    @job.send(:finalize_chunking_setup, batches)
    assert_equal 3, @job.instance_variable_get(:@batches_count)
  end

  def test_finalize_chunking_setup_doesnt_set_batches_count_or_close_before_initial_batch_is_ready
    batches = [
      {"id"=> "55024000002iETSAA2", "state"=> "Queued"},
    ]
    @job.instance_variable_set(:@initial_batch_id, "55024000002iETSAA2")
    @job.expects(:close).never

    @job.send(:finalize_chunking_setup, batches)
    assert_nil @job.instance_variable_get(:@batches_count)
  end

end
