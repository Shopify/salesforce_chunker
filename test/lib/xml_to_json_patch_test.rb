require "test_helper"

class XMLToJSONPatchTest < Minitest::Test
  def test_create_batch
    assert_equal create_batch_output, SalesforceChunker::XMLToJSONPatch.create_batch(create_batch_jsonized)
  end

  def test_batch_statuses_single
    assert_equal batch_statuses_single_output, SalesforceChunker::XMLToJSONPatch.get_batch_statuses(batch_statuses_single_jsonized)
  end

  def test_batch_statuses_multiple
    assert_equal batch_statuses_multiple_output, SalesforceChunker::XMLToJSONPatch.get_batch_statuses(batch_statuses_multiple_jsonized)
  end

  def test_result_single
    assert_equal result_single_output, SalesforceChunker::XMLToJSONPatch.retrieve_batch_results(result_single_jsonized)
  end

  def test_result_multiple
    assert_equal result_multiple_output, SalesforceChunker::XMLToJSONPatch.retrieve_batch_results(result_multiple_jsonized)
  end

  def test_apply_calls_create_batch
    SalesforceChunker::XMLToJSONPatch.expects(:create_batch).with("xyz")
    SalesforceChunker::XMLToJSONPatch.apply("POST", "job/uG32ThKe728wwBu/batch", "xyz")
  end

  def test_apply_calls_get_batch_statuses
    SalesforceChunker::XMLToJSONPatch.expects(:get_batch_statuses).with("abc")
    SalesforceChunker::XMLToJSONPatch.apply("GET", "job/uG32ThKe728wwBu/batch", "abc")
  end

  def test_apply_calls_retrieve_batch_results
    SalesforceChunker::XMLToJSONPatch.expects(:retrieve_batch_results).with("123")
    SalesforceChunker::XMLToJSONPatch.apply("GET", "job/uG32ThKe728wwBu/batch/pp7WgBVi7xBRuRR/result", "123")
  end

  private

  def create_batch_jsonized
    {
      "batchInfo" =>
      {
        "xmlns"=>"http://www.force.com/2009/06/asyncapi/dataload",
        "id"=>"8hAiJGfxDD8o687",
        "jobId"=>"uG32ThKe728wwBu",
        "state"=>"Queued",
        "createdDate"=>"2018-10-18T18:17:33.000Z",
        "systemModstamp"=>"2018-10-18T18:17:33.000Z",
        "numberRecordsProcessed"=>"0",
        "numberRecordsFailed"=>"0",
        "totalProcessingTime"=>"0",
        "apiActiveProcessingTime"=>"0",
        "apexProcessingTime"=>"0"
      }
    }
  end

  def create_batch_output
    {
      "xmlns"=>"http://www.force.com/2009/06/asyncapi/dataload",
      "id"=>"8hAiJGfxDD8o687",
      "jobId"=>"uG32ThKe728wwBu",
      "state"=>"Queued",
      "createdDate"=>"2018-10-18T18:17:33.000Z",
      "systemModstamp"=>"2018-10-18T18:17:33.000Z",
      "numberRecordsProcessed"=>"0",
      "numberRecordsFailed"=>"0",
      "totalProcessingTime"=>"0",
      "apiActiveProcessingTime"=>"0",
      "apexProcessingTime"=>"0"
    }
  end

  def batch_statuses_single_jsonized
    {
      "batchInfoList"=>
      {
        "xmlns"=>"http://www.force.com/2009/06/asyncapi/dataload",
        "batchInfo"=>
        {
          "id"=>"pp7WgBVi7xBRuRR",
          "jobId"=>"uG32ThKe728wwBu",
          "state"=>"Completed",
          "createdDate"=>"2018-10-18T18:14:36.000Z",
          "systemModstamp"=>"2018-10-18T18:14:36.000Z",
          "numberRecordsProcessed"=>"4645",
          "numberRecordsFailed"=>"0",
          "totalProcessingTime"=>"0",
          "apiActiveProcessingTime"=>"0",
          "apexProcessingTime"=>"0"
        }
      }
    }
  end

  def batch_statuses_single_output
    {
      "batchInfo"=> [
        {
          "id"=>"pp7WgBVi7xBRuRR",
          "jobId"=>"uG32ThKe728wwBu",
          "state"=>"Completed",
          "createdDate"=>"2018-10-18T18:14:36.000Z",
          "systemModstamp"=>"2018-10-18T18:14:36.000Z",
          "numberRecordsProcessed"=>"4645",
          "numberRecordsFailed"=>"0",
          "totalProcessingTime"=>"0",
          "apiActiveProcessingTime"=>"0",
          "apexProcessingTime"=>"0"
        }
      ]
    }
  end

  def batch_statuses_multiple_jsonized
    {"batchInfoList"=>
      {"xmlns"=>"http://www.force.com/2009/06/asyncapi/dataload",
       "batchInfo"=>
        [
          {
            "id"=>"pR88XqDwqeFV8z3",
            "jobId"=>"uG32ThKe728wwBu",
            "state"=>"NotProcessed",
            "createdDate"=>"2018-10-17T19:17:05.000Z",
            "systemModstamp"=>"2018-10-17T19:17:05.000Z",
            "numberRecordsProcessed"=>"0",
            "numberRecordsFailed"=>"0",
            "totalProcessingTime"=>"0",
            "apiActiveProcessingTime"=>"0",
            "apexProcessingTime"=>"0"
          },
          {
            "id"=>"iPjucw8Ayy9t2Nr",
            "jobId"=>"uG32ThKe728wwBu",
            "state"=>"Completed",
            "createdDate"=>"2018-10-17T19:17:05.000Z",
            "systemModstamp"=>"2018-10-17T19:17:05.000Z",
            "numberRecordsProcessed"=>"4",
            "numberRecordsFailed"=>"0",
            "totalProcessingTime"=>"0",
            "apiActiveProcessingTime"=>"0",
            "apexProcessingTime"=>"0"
          }
        ]
      }
    }
  end

  def batch_statuses_multiple_output
    {
      "xmlns"=>"http://www.force.com/2009/06/asyncapi/dataload",
      "batchInfo"=> [
        {
          "id"=>"pR88XqDwqeFV8z3",
          "jobId"=>"uG32ThKe728wwBu",
          "state"=>"NotProcessed",
          "createdDate"=>"2018-10-17T19:17:05.000Z",
          "systemModstamp"=>"2018-10-17T19:17:05.000Z",
          "numberRecordsProcessed"=>"0",
          "numberRecordsFailed"=>"0",
          "totalProcessingTime"=>"0",
          "apiActiveProcessingTime"=>"0",
          "apexProcessingTime"=>"0"
        },
        {
          "id"=>"iPjucw8Ayy9t2Nr",
          "jobId"=>"uG32ThKe728wwBu",
          "state"=>"Completed",
          "createdDate"=>"2018-10-17T19:17:05.000Z",
          "systemModstamp"=>"2018-10-17T19:17:05.000Z",
          "numberRecordsProcessed"=>"4",
          "numberRecordsFailed"=>"0",
          "totalProcessingTime"=>"0",
          "apiActiveProcessingTime"=>"0",
          "apexProcessingTime"=>"0"
        }
      ]
    }
  end

  def result_single_jsonized
    {
      "result_list" => {
        "xmlns" => "http://www.force.com/2009/06/asyncapi/dataload",
        "result" => "ht86B9NHwkms94b"
      }
    }
  end

  def result_single_output
    [
      "ht86B9NHwkms94b",
    ]
  end

  # unsure about this one
  def result_multiple_jsonized
    {
      "result_list" => {
        "xmlns" => "http://www.force.com/2009/06/asyncapi/dataload",
        "result" => [
          "Qh3FQEJ4v6TJDmn",
          "6Fv6Bhd8WWyFsn2",
        ]
      }
    }
  end

  def result_multiple_output
    [
      "Qh3FQEJ4v6TJDmn",
      "6Fv6Bhd8WWyFsn2",
    ]
  end
end
