require "test_helper"

class ManualChunkingQueryTest < Minitest::Test

  def setup
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:create_job)
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:breakpoints)
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:create_batches)
    SalesforceChunker::ManualChunkingQuery.any_instance.stubs(:close)
    @job = SalesforceChunker::ManualChunkingQuery.new(connection: nil, object: nil, operation: "query", query: "")
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:create_job)
    SalesforceChunker::ManualChunkingQuery.any_instance.unstub(:breakpoints)
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

  def test_breakpoints_creates_batch_correctly_and_sets_batches_count
    @job.expects(:create_batch).with(
      "Select Id From CustomObject82__c Where SystemModStamp >= 2018-09-15T10:00:00Z Order By Id Asc"
    )
    @job.stubs(:download_results).returns([].to_enum)


    @job.breakpoints("CustomObject82__c", "Where SystemModStamp >= 2018-09-15T10:00:00Z", 3)

    assert_equal 1, @job.instance_variable_get(:@batches_count)
  end

  def test_breakpoints_empty_if_smaller_than_batch_size
    @job.stubs(:create_batch)
    @job.stubs(:download_results).returns([
      {"Id" => "id0"},
      {"Id" => "id1"},
    ].to_enum)

    assert_empty @job.breakpoints("", "", 3)
  end

  def test_breakpoints_empty_if_equal_to_batch_size
    @job.stubs(:create_batch)
    @job.stubs(:download_results).returns([
      {"Id" => "id0"},
      {"Id" => "id1"},
      {"Id" => "id2"},
    ].to_enum)

    assert_empty @job.breakpoints("", "", 3)
  end

  def test_breakpoints_returns_one_point
    @job.stubs(:create_batch)
    @job.stubs(:download_results).returns([
      {"Id" => "id0"},
      {"Id" => "id1"},
      {"Id" => "id2"},
      {"Id" => "id3"},
    ].to_enum)

    assert_equal ["id3"], @job.breakpoints("", "", 3)
  end

  def test_breakpoints_returns_multiple_points
    @job.stubs(:create_batch)
    @job.stubs(:download_results).returns([
      {"Id" => "id0"},
      {"Id" => "id1"},
      {"Id" => "id2"},
      {"Id" => "id3"},
      {"Id" => "id4"},
      {"Id" => "id5"},
      {"Id" => "id6"},
      {"Id" => "id7"},
    ].to_enum)

    assert_equal ["id3", "id6"], @job.breakpoints("", "", 3)
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



  # def test_initialize_creates_job_and_batch

  #   # create_job

  #   # stub others

    

  #   SalesforceChunker::Job.any_instance.expects(:create_job)

  #   SalesforceChunker::Job.any_instance.expects(:create_batch)
  #     .with("Select CustomColumn__c From CustomObject__c")
  #     .returns("55024000002iETSAA2")

  #   job = SalesforceChunker::PrimaryKeyChunkingQuery.new(
  #     connection: "connect",
  #     object: "CustomObject__c",
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
