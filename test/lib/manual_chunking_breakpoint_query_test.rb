require "test_helper"

class ManualChunkingBreakpointQueryTest < Minitest::Test

  def setup
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:create_job)
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:breakpoints)
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:close)
    @job = SalesforceChunker::ManualChunkingBreakpointQuery.new(connection: nil, object: nil, operation: "query", query: "")
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:create_job)
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:create_batch)
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:close)
    @job.instance_variable_set(:@job_id, "3811P00000EFQiYQAX")
  end

end
