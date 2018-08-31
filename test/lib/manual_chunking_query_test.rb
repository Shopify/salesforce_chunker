require "test_helper"

class ManualChunkingQueryTest < Minitest::Test

  def setup
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:create_job)
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:id_breakpoints)
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:create_batches)
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:close)
    @job = SalesforceChunker::ManualChunkingQuery.new(connection: nil, entity: nil, operation: "query", query: "")
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:create_job)
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:id_breakpoints)
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:create_batches)
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:close)
    @job.instance_variable_set(:@job_id, "3811P00000EFQiYQAX")
  end

  def test_get_batch_statuses_returns_only_initial_batch
    initial_batch = {"id"=> "55024000002iETSAA2", "state"=> "Completed"}

    connection = mock()
    connection.expects(:get_json).with(
      "job/3811P00000EFQiYQAX/batch",
    ).returns({"batchInfo" => [
      initial_batch,
    ]})

    @job.instance_variable_set(:@connection, connection)
    @job.instance_variable_set(:@initial_batch_id, "55024000002iETSAA2")

    assert_equal [initial_batch], @job.get_batch_statuses
  end

  def test_get_batch_statuses_skips_initial_batch_when_others_created
    initial_batch = {"id"=> "55024000002iETSAA2", "state"=> "Completed"}
    another_batch = {"id"=> "55024000002iETTAA2", "state"=> "InProgress"}

    connection = mock()
    connection.expects(:get_json).with(
      "job/3811P00000EFQiYQAX/batch",
    ).returns({"batchInfo" => [
      initial_batch,
      another_batch,
    ]})

    @job.instance_variable_set(:@connection, connection)
    @job.instance_variable_set(:@initial_batch_id, "55024000002iETSAA2")

    assert_equal [another_batch], @job.get_batch_statuses
  end

  def test_create_batch_increments_batches_count
    connection = mock()
    connection.expects(:post).with(
      "job/3811P00000EFQiYQAX/batch", 
      "Select CustomColumn__c From CustomObject__c",
    ).returns({
      "id" => "55024000002iETSAA2"
    })
    @job.instance_variable_set(:@connection, connection)

    @job.create_batch("Select CustomColumn__c From CustomObject__c")
    assert_equal 1,  @job.instance_variable_get(:@batches_count)
  end

  def test_id_breakpoints_one


    @job.id_breakpoints("Select CustomColumn__c From CustomObject__c")
  end

  #def test_get_batch_statuses_skips_initial_batch




  #end

  # def test_initialize_creates_job_and_batch

  #   # create_job

  #   # stub others

    

  #   SalesforceChunker::Job.any_instance.expects(:create_job)

  #   SalesforceChunker::Job.any_instance.expects(:create_batch)
  #     .with("Select CustomColumn__c From CustomObject__c")
  #     .returns("55024000002iETSAA2")

  #   job = SalesforceChunker::PrimaryKeyChunkingQuery.new(
  #     connection: "connect",
  #     entity: "CustomObject__c",
  #     operation: "query",
  #     query: "Select CustomColumn__c From CustomObject__c",
  #     batch_size: 4300,
  #   )

  #   assert_equal "connect", job.instance_variable_get(:@connection)
  #   assert_equal "query", job.instance_variable_get(:@operation)
  #   assert_equal "55024000002iETSAA2", job.instance_variable_get(:@initial_batch_id)
  #   assert_equal "3811P00000EFQiYQAZ", job.instance_variable_get(:@job_id)
  #end

end
