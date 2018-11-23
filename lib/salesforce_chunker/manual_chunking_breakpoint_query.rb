module SalesforceChunker
  class ManualChunkingBreakpointQuery < Job

    def initialize(connection:, object:, operation:, **options)
      @batch_size = options[:batch_size] || 100000
      super(connection: connection, object: object, operation: operation, **options)

      @log.info "Creating Breakpoint Query"
      create_batch("Select Id From #{object}")

      @batches_count = 1
      close
    end

    def get_batch_results(batch_id)
      retrieve_batch_results(batch_id).each do |result_id|
        results = retrieve_raw_results(batch_id, result_id)

        process_csv_results(results) { |result| yield result }
      end
    end

    def process_csv_results(result)
      lines = result.each_line
      headers = lines.next

      loop do
        begin
          @batch_size.times { lines.next }
          yield(lines.peek.chomp.gsub("\"", ""))
        rescue StopIteration
          break
        end
      end
    end

    def create_batch(payload)
      @log.info "Creating Id Batch: \"#{payload.gsub(/\n/, " ").strip}\""
      response = @connection.post("job/#{@job_id}/batch", payload.to_s, {"Content-Type": "text/csv"})
      response["batchInfo"]["id"]
    end

    def retrieve_batch_results(batch_id)
      # XML to JSON wrangling
      response = super(batch_id)
      if response["result_list"]["result"].is_a? Array
        response["result_list"]["result"]
      else
        [response["result_list"]["result"]]
      end
    end

    def get_batch_statuses
      # XML to JSON wrangling
      [@connection.get_json("job/#{@job_id}/batch")["batchInfoList"]["batchInfo"]]
    end

    def create_job(object, options)
      super(object, options.merge(content_type: "CSV"))
    end
  end
end
