require "test_helper"

class ManualChunkingQueryTest < Minitest::Test

  def setup
    manual_chunking_breakpoint_query = mock()
    manual_chunking_breakpoint_query.stubs(:download_results).with(retry_seconds: 10).yields()

    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:create_job)
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:create_batch)
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:close)
    SalesforceChunker::ManualChunkingBreakpointQuery.stubs(:new).returns(manual_chunking_breakpoint_query)
    @job = SalesforceChunker::ManualChunkingQuery.new(connection: nil, object: nil, operation: "query", query: "")
    SalesforceChunker::ManualChunkingBreakpointQuery.unstub(:new)
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:create_job)
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:create_batch)
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:close)
    @job.instance_variable_set(:@job_id, "3811P00000EFQiYQAX")
  end

  def test_where_clause_exists
    query = "Select Id From CustomObject26__c Where SystemModStamp >= 2018-08-08T00:02:00Z"
    where_clause = "Where SystemModStamp >= 2018-08-08T00:02:00Z"
    assert_equal where_clause, SalesforceChunker::ManualChunkingQuery.query_where_clause(query)
  end

  def test_where_clause_empty
    query = "Select Id From CustomObject63__c"
    assert_empty SalesforceChunker::ManualChunkingQuery.query_where_clause(query)
  end

  def test_create_batches_with_empty_breakpoints
    @job.expects(:create_batch).with("Select Id, Name From CustomObject19__c")
    @job.create_batches("Select Id, Name From CustomObject19__c", [], "")
    assert_equal 1, @job.instance_variable_get(:@batches_count)
  end

  def test_create_batches_with_one_breakpoint
    @job.expects(:create_batch).with("Select Id, Name From CustomObject95__c Where Id < 'id55'").once
    @job.expects(:create_batch).with("Select Id, Name From CustomObject95__c Where Id >= 'id55'").once

    @job.create_batches("Select Id, Name From CustomObject95__c", ["id55"], "")

    assert_equal 2, @job.instance_variable_get(:@batches_count)
  end

  def test_create_batches_with_multiple_breakpoints
    @job.expects(:create_batch).with("Select Id, Name From CustomObject43__c Where Id < 'id23'").once
    @job.expects(:create_batch).with("Select Id, Name From CustomObject43__c Where Id >= 'id23' And Id < 'id59'").once
    @job.expects(:create_batch).with("Select Id, Name From CustomObject43__c Where Id >= 'id59' And Id < 'id83'").once
    @job.expects(:create_batch).with("Select Id, Name From CustomObject43__c Where Id >= 'id83'").once

    @job.create_batches("Select Id, Name From CustomObject43__c", ["id23", "id59", "id83"], "")

    assert_equal 4, @job.instance_variable_get(:@batches_count)
  end

  def test_create_batches_with_multiple_breakpoints_and_where_clause
    query = "Select Id, Name From CustomObject43__c Where SystemModStamp >= 2018-09-11T00:00:00Z"
    where_clause = "Where SystemModStamp >= 2018-09-11T00:00:00Z"

    @job.expects(:create_batch).with("Select Id, Name From CustomObject43__c Where SystemModStamp >= 2018-09-11T00:00:00Z And Id < 'id23'").once
    @job.expects(:create_batch).with("Select Id, Name From CustomObject43__c Where SystemModStamp >= 2018-09-11T00:00:00Z And Id >= 'id23' And Id < 'id59'").once
    @job.expects(:create_batch).with("Select Id, Name From CustomObject43__c Where SystemModStamp >= 2018-09-11T00:00:00Z And Id >= 'id59' And Id < 'id83'").once
    @job.expects(:create_batch).with("Select Id, Name From CustomObject43__c Where SystemModStamp >= 2018-09-11T00:00:00Z And Id >= 'id83'").once

    @job.create_batches(query, ["id23", "id59", "id83"], where_clause)
  end

  def test_initialize_creates_job_and_batches
    manual_chunking_breakpoint_query = mock()
    manual_chunking_breakpoint_query.expects(:download_results).with(retry_seconds: 10)
      .returns(["55024000002iETWAA3"].to_enum)

    SalesforceChunker::ManualChunkingBreakpointQuery.expects(:new).with(
      has_entries(
        connection: "connect",
        object: "CustomObject__c",
        operation: "query",
        batch_size: 8600,
        query: "Select Id From CustomObject__c Where SystemModStamp >= 2018-09-12T00:00:00Z Order By Id Asc",
      )
    ).returns(manual_chunking_breakpoint_query)

    SalesforceChunker::Job.any_instance.expects(:create_job)
      .with("CustomObject__c", {})
      .returns("3811P00000EFQiYQAZ")

    SalesforceChunker::ManualChunkingQuery.any_instance.expects(:create_batches).with(
      "Select CustomColumn__c From CustomObject__c Where SystemModStamp >= 2018-09-12T00:00:00Z",
      ["55024000002iETWAA3"],
      "Where SystemModStamp >= 2018-09-12T00:00:00Z",
    )

    SalesforceChunker::ManualChunkingQuery.any_instance.expects(:close)

    job = SalesforceChunker::ManualChunkingQuery.new(
      connection: "connect",
      object: "CustomObject__c",
      operation: "query",
      query: "Select CustomColumn__c From CustomObject__c Where SystemModStamp >= 2018-09-12T00:00:00Z",
      batch_size: 8600,
    )

    assert_equal "connect", job.instance_variable_get(:@connection)
    assert_equal "query", job.instance_variable_get(:@operation)
    assert_equal "3811P00000EFQiYQAZ", job.instance_variable_get(:@job_id)
  end
end
