module SalesforceChunker
  class Job
    attr_reader :batches_count

    def initialize(connection:, entity:, operation:, **options)
      @connection = connection
      @operation = operation
      @batches_count = nil
      @job_id = create_job(entity, options[:headers])
    end

    def get_completed_batches
      get_batch_statuses.select do |batch|
        raise BatchError, "Batch failed: #{batch["stateMessage"]}" if batch["state"] == "Failed"
        raise RecordError, "Failed records in batch" if batch["state"] == "Completed" && batch["numberRecordsFailed"] > 0
        batch["state"] == "Completed"
      end
    end

    def get_batch_results(batch_id)
      retrieve_batch_results(batch_id).each do |result_id|
        retrieve_results(batch_id, result_id).each do |result|
          result.tap { |h| h.delete("attributes") }
          yield(result)
        end
      end
    end

    def create_batch(query)
      @connection.post("job/#{@job_id}/batch", query)["id"]
    end

    def get_batch_statuses
      @connection.get_json("job/#{@job_id}/batch")["batchInfo"]
    end

    def retrieve_batch_results(batch_id)
      @connection.get_json("job/#{@job_id}/batch/#{batch_id}/result")
    end

    def retrieve_results(batch_id, result_id)
      @connection.get_json("job/#{@job_id}/batch/#{batch_id}/result/#{result_id}")
    end

    def close
      body = {"state": "Closed"}
      @connection.post_json("job/#{@job_id}/", body)
    end

    private

    def create_job(entity, headers = {})
      body = {
        "operation": @operation,
        "object": entity,
        "contentType": "JSON"
      }
      @connection.post_json("job", body, headers)["id"]
    end
  end
end
