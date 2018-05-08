module SalesforceChunker
  class Job
    attr_reader :batches_count

    def initialize(connection, soql, batch_size)
      @connection = connection
      @job_id = ""
      @batches_count = nil

      create_job(batch_size)
      create_batch(soql)
    end

    def get_batch_statuses
      response = @connection.get_json("job/#{@job_id}/batch")
      batches = response["batchInfo"]
      first_batch = batches.shift

      if @batches_count.nil?
        if first_batch && first_batch["state"] == "NotProcessed"
          @batches_count = batches.length
          close
        else
          return []
        end
      end
      batches
    end

    def retrieve_batch_results(batch_id)
      @connection.get_json("job/#{@job_id}/batch/#{batch_id}/result")
    end

    def retrieve_results(batch_id, result_id)
      @connection.get_json("job/#{@job_id}/batch/#{batch_id}/result/#{result_id}")
    end

    private

    def create_job(batch_size=10000)
      headers = {"Sforce-Enable-PKChunking": "true; chunkSize=#{batch_size};" }
      body = {
        "operation": "query", 
        "object": "Account", 
        "contentType": "JSON"
      }.to_json

      response = @connection.post_json("job", body, headers)
      @job_id = response["id"]
    end

    def create_batch(soql)
      response = @connection.post_json("job/#{@job_id}/batch", soql)
    end

    def close
      body = {"state": "Closed"}.to_json
      @connection.post_json("job/#{@job_id}/", body)
    end
  end
end