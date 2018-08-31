require "test_helper"

class SalesforceChunkerTest < Minitest::Test

  def setup
    SalesforceChunker::Connection.stubs(:new)
    @client = SalesforceChunker::Client.new({})
    SalesforceChunker::Connection.unstub(:new)
  end

  def test_that_it_has_a_version_number
    refute_nil ::SalesforceChunker::VERSION
  end

  def test_raise_error_when_no_block_given_in_query
    assert_raises StandardError do
      @client.query("", "")
    end
  end

  def test_query
    job = mock()
    job.expects(:download_results).yields({"CustomColumn__c" => "abc"})

    actual_results = []
    expected_results = [
      {"CustomColumn__c" => "abc"},
    ]

    SalesforceChunker::PrimaryKeyChunkingQuery.stubs(:new).returns(job)

    @client.query("", "", retry_seconds: 0) { |result| actual_results << result }
    assert_equal expected_results, actual_results
  end

  def test_query_with_job_type_single_batch
    job = mock()
    job.expects(:download_results).yields({"CustomColumn__c" => "abc"})

    actual_results = []
    expected_results = [
      {"CustomColumn__c" => "abc"},
    ]

    SalesforceChunker::SingleBatchJob.stubs(:new).returns(job)

    @client.query("", "", retry_seconds: 0, job_type: "single_batch") { |result| actual_results << result }
    assert_equal expected_results, actual_results
  end

  def test_single_batch_query
    @client.expects(:query).with("q", "e", job_type: "single_batch")
    @client.single_batch_query("q", "e") {}
  end

  def test_primary_key_chunking_query
    @client.expects(:query).with("q", "e", job_type: "primary_key_chunking")
    @client.primary_key_chunking_query("q", "e") {}
  end
end
