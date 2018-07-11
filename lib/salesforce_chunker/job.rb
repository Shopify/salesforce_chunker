module SalesforceChunker
  class Job
    attr_reader :batches_count

    def initialize(connection, query, entity, batch_size)
      @connection = connection
      @batches_count = nil
      @job_id = create_job(entity, batch_size)
      @initial_batch_id = create_batch(query)
    end

    def get_completed_batches
      get_batch_statuses.select do |batch|
        raise BatchError, "Batch failed: #{batch["stateMessage"]}" if batch["state"] == "Failed"
        raise RecordError, "Failed records in batch" if batch["state"] == "Completed" && batch["numberRecordsFailed"] > 0
        batch["state"] == "Completed"
      end
    end

    def get_batch_statuses
      response = @connection.get_json("job/#{@job_id}/batch")
      finalize_chunking_setup(response["batchInfo"]) if @batches_count.nil?
      response["batchInfo"]
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
      @connection.post_json("job/#{@job_id}/batch", query)["id"]
    end

    def retrieve_batch_results(batch_id)
      @connection.get_json("job/#{@job_id}/batch/#{batch_id}/result")
    end

    def retrieve_results(batch_id, result_id)
      @connection.get_json("job/#{@job_id}/batch/#{batch_id}/result/#{result_id}")
    end

    def close
      body = {"state": "Closed"}.to_json
      @connection.post_json("job/#{@job_id}/", body)
    end

    private

    def create_job(entity, batch_size)
      headers = {"Sforce-Enable-PKChunking": "true; chunkSize=#{batch_size};" }
      body = {
        "operation": "query",
        "object": entity,
        "contentType": "JSON"
      }.to_json
      @connection.post_json("job", body, headers)["id"]
    end

    def finalize_chunking_setup(batches)
      initial_batch = batches.select { |batch| batch["id"] == @initial_batch_id }.first
      if initial_batch && initial_batch["state"] == "NotProcessed"
        @batches_count = batches.length - 1
        close
      end
    end
  end
end
