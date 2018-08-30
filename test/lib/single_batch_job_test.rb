require "test_helper"

class SingleBatchJobTest < Minitest::Test

  def test_initialize_creates_job_and_batch_and_closes
    SalesforceChunker::SingleBatchJob.any_instance.expects(:create_job)
      .with("Object", {})
      .returns("3811P00000EFQiYQAG")

    SalesforceChunker::SingleBatchJob.any_instance.expects(:create_batch)
      .with("Select Id from Object")
      .returns("3811P00000EFQiYQAJ")

    SalesforceChunker::SingleBatchJob.any_instance.expects(:close)

    job = SalesforceChunker::SingleBatchJob.new(
      connection: "connect",
      entity: "Object",
      operation: "query",
      payload: "Select Id from Object",
    )

    assert_equal "connect", job.instance_variable_get(:@connection)
    assert_equal "query", job.instance_variable_get(:@operation)
    assert_equal "3811P00000EFQiYQAG", job.instance_variable_get(:@job_id)
    assert_equal "3811P00000EFQiYQAJ", job.instance_variable_get(:@batch_id)
    assert_equal 1, job.instance_variable_get(:@batches_count)
  end
end
