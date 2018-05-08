module SalesforceChunker
  class Job
    attr_reader :batch_ids

    def initialize(connection, soql, batch_size)
      @connection = connection
      @job_id = ""
      @batch_ids = []

      create_job(batch_size)
      create_batch(soql)

      36.times do # timeout after 3 minutes
        sleep(5)
        statuses = get_batch_statuses
        first_batch = statuses.shift
        if first_batch && first_batch["state"] == "NotProcessed"
          @batch_ids = statuses.map { |batch| batch["id"] }
          break
        end
      end

      close
      raise RuntimeError("Batch Creation Failed") if @batch_ids.empty?
    end

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

    def get_batch_statuses
      response = @connection.get_json("job/#{@job_id}/batch")
      response["batchInfo"]
    end

    def retrieve_batch_results(batch_id)
      @connection.get_json("job/#{@job_id}/batch/#{batch_id}/result") #.each do |result_id|
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