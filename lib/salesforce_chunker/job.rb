module SalesforceChunker
  class Job
    attr_reader :batches_count

    def initialize(connection, query, entity, batch_size)
      @connection = connection
      @job_id = ""
      @initial_batch_id = ""
      @batches_count = nil

      create_job(entity, batch_size)
      create_batch(query)
    end

    def get_batch_statuses
      response = @connection.get_json("job/#{@job_id}/batch")
      batches = response["batchInfo"]

      if @batches_count.nil?
        initial_batch = batches.select { |batch| batch["id"] == @initial_batch_id }.first
        if initial_batch && initial_batch["state"] == "NotProcessed"
          @batches_count = batches.length - 1
          close
        end
      end
      batches
    end

    def get_batch_results(batch_id)
      retrieve_batch_results(batch_id).each do |result_id|
        retrieve_results(batch_id, result_id).each do |result|
          result.tap { |h| h.delete("attributes") }
          yield(result)
        end
      end
    end

    private

    def create_job(entity, batch_size)
      headers = {"Sforce-Enable-PKChunking": "true; chunkSize=#{batch_size};" }
      body = {
        "operation": "query",
        "object": entity,
        "contentType": "JSON"
      }.to_json

      response = @connection.post_json("job", body, headers)
      @job_id = response["id"]
    end

    def create_batch(query)
      response = @connection.post_json("job/#{@job_id}/batch", query)
      @initial_batch_id = response["id"]
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
  end
end
