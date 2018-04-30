module SalesforceChunker
  class Job

    def initialize(connection, soql, batch_size)
      @connection = connection
      @job_id = ""
      @retrieved_batches = []

      create_job(batch_size)
      create_batch(soql)
    end

    def create_job(batch_size=1000)
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
      # print response
      # response.code == 201
    end

    def get_batch_statuses
      response = @connection.get_json("job/#{@job_id}/batch")
      response["batchInfo"]
    end

    def retrieve_batch_results(batch_id)
      @connection.get_json("job/#{@job_id}/batch/#{batch_id}/result").each do |result_id|
        retrieve_results(batch_id, result_id)
      end
      @retrieved_batches.append(batch_id)
    end

    def retrieve_results(batch_id, result_id)
      results = @connection.get_json("job/#{@job_id}/batch/#{batch_id}/result/#{result_id}")
    end

    def close
      body = {"state": "Closed"}.to_json
      response = @connection.post_json("job/#{@job_id}/", body)
      # response.ok?
    end
  end
end