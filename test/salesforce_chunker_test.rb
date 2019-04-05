require "test_helper"

class SalesforceChunkerTest < Minitest::Test

  def setup
    SalesforceChunker::Connection.stubs(:new)
    @client = SalesforceChunker::Client.new(query: "", object: "")
    SalesforceChunker::Connection.unstub(:new)
  end

  def test_that_it_has_a_version_number
    refute_nil ::SalesforceChunker::VERSION
  end

  def test_query
    job = mock()
    job.expects(:download_results).yields({"CustomColumn__c" => "abc"})
    SalesforceChunker::PrimaryKeyChunkingQuery.stubs(:new).returns(job)

    actual_results = []
    @client.query(query: "", object: "", retry_seconds: 0) { |result| actual_results << result }

    assert_equal [{"CustomColumn__c" => "abc"}], actual_results
  end

  def test_query_as_enumerator
    job = mock()
    job.expects(:download_results).yields({"CustomColumn__c" => "abc"})
    SalesforceChunker::PrimaryKeyChunkingQuery.stubs(:new).returns(job)

    actual_results = @client.query(query: "", object: "", retry_seconds: 0)

    assert_equal "Enumerator", actual_results.class.name
    assert_equal [{"CustomColumn__c" => "abc"}], actual_results.to_a
  end

  def test_query_include_deleted
    job = mock()
    job.expects(:download_results).yields({"CustomColumn__c" => "abc"})
    SalesforceChunker::PrimaryKeyChunkingQuery.stubs(:new).with(has_entry(operation: "queryAll")).returns(job)

    actual_results = []
    @client.query(query: "", object: "", retry_seconds: 0, include_deleted: true) { |result| actual_results << result }

    assert_equal [{"CustomColumn__c" => "abc"}], actual_results
  end

  def test_query_with_job_type_single_batch
    job = mock()
    job.expects(:download_results).yields({"CustomColumn__c" => "abc"})
    SalesforceChunker::SingleBatchJob.stubs(:new).returns(job)
    
    actual_results = []
    @client.query(query: "", object: "", retry_seconds: 0, job_type: "single_batch") { |result| actual_results << result }

    assert_equal [{"CustomColumn__c" => "abc"}], actual_results
  end

  def test_query_with_job_type_manual_chunking
    job = mock()
    job.expects(:download_results).yields({"CustomColumn__c" => "abc"})
    SalesforceChunker::ManualChunkingQuery.stubs(:new).returns(job)

    actual_results = []
    @client.query(query: "", object: "", retry_seconds: 0, job_type: "manual_chunking") { |result| actual_results << result }

    assert_equal [{"CustomColumn__c" => "abc"}], actual_results
  end

  def test_single_batch_query
    @client.expects(:query).with(query: "q", object: "o", job_type: "single_batch")
    @client.single_batch_query(query: "q", object: "o") {}
  end

  def test_primary_key_chunking_query
    @client.expects(:query).with(query: "q", object: "o", job_type: "primary_key_chunking")
    @client.primary_key_chunking_query(query: "q", object: "o") {}
  end

  def test_manual_chunking_query
    @client.expects(:query).with(query: "q", object: "o", job_type: "manual_chunking")
    @client.manual_chunking_query(query: "q", object: "o") {}
  end
end
