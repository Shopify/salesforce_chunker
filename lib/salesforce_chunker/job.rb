module SalesforceChunker
  class Job
    attr_reader :batches_count

    QUERY_OPERATIONS = ["query", "queryall"].freeze
    DEFAULT_RETRY_SECONDS = 10
    DEFAULT_TIMEOUT_SECONDS = 3600

    def initialize(connection:, object:, operation:, **options)
      @log = options[:logger] || Logger.new(options[:log_output])
      @log.progname = "salesforce_chunker"

      @connection = connection
      @operation = operation
      @batches_count = nil

      @log.info "Creating Bulk API Job"
      @job_id = create_job(object, options.slice(:headers, :external_id))
    end

    def download_results(**options)
      return nil unless QUERY_OPERATIONS.include?(@operation)
      return to_enum(:download_results, **options) unless block_given?

      retry_seconds = options[:retry_seconds] || DEFAULT_RETRY_SECONDS
      timeout_at = Time.now.utc + (options[:timeout_seconds] || DEFAULT_TIMEOUT_SECONDS)
      downloaded_batches = []

      loop do
        @log.info "Retrieving batch status information"
        get_completed_batches.each do |batch|
          next if downloaded_batches.include?(batch["id"])
          @log.info "Batch #{downloaded_batches.length + 1} of #{@batches_count || '?'}: " \
            "retrieving #{batch["numberRecordsProcessed"]} records"
          get_batch_results(batch["id"]) { |result| yield(result) } if batch["numberRecordsProcessed"] > 0
          downloaded_batches.append(batch["id"])
        end

        break if @batches_count && downloaded_batches.length == @batches_count
        raise TimeoutError, "Timeout during batch processing" if Time.now.utc > timeout_at

        @log.info "Waiting #{retry_seconds} seconds"
        sleep(retry_seconds)
      end
      
      @log.info "Completed"
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

    def create_batch(payload)
      if QUERY_OPERATIONS.include?(@operation)
        @log.info "Creating #{@operation.capitalize} Batch: \"#{payload.gsub(/\n/, " ").strip}\""
        @connection.post("/job/#{@job_id}/batch", payload.to_s)["id"]
      else
        @log.info "Creating #{@operation.capitalize} Batch"
        @connection.post_json("/job/#{@job_id}/batch", payload)["id"]
      end
    end

    def get_batch_statuses
      @connection.get_json("/job/#{@job_id}/batch")["batchInfo"]
    end

    def retrieve_batch_results(batch_id)
      @connection.get_json("/job/#{@job_id}/batch/#{batch_id}/result")
    end

    def retrieve_results(batch_id, result_id)
      @connection.get_json("/job/#{@job_id}/batch/#{batch_id}/result/#{result_id}")
    end

    def close
      body = {"state": "Closed"}
      @connection.post_json("/job/#{@job_id}", body)
    end

    private

    def create_job(object, options)
      body = {
        "operation": @operation,
        "object": object,
        "contentType": "JSON",
      }
      body[:externalIdFieldName] = options[:external_id] if @operation == "upsert"
      @connection.post_json("/job", body, options[:headers].to_h)["id"]
    end
  end
end
