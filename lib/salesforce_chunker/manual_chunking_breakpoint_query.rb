module SalesforceChunker
  class ManualChunkingBreakpointQuery < Job

    def initialize(connection:, object:, operation:, query:, **options)
      @batch_size = options[:batch_size] || 100000
      super(connection: connection, object: object, operation: operation, **options)

      create_batch(query)
      @batches_count = 1

      close
    end

    def get_batch_results(batch_id)
      retrieve_batch_results(batch_id).each_with_index do |result_id, result_index|
        results = retrieve_raw_results(batch_id, result_id)

        @log.info "Generating breakpoints from CSV results"
        process_csv_results(results, result_index > 0) { |result| yield result }
      end
    end

    def process_csv_results(input, include_first_element)
      lines = input.each_line
      headers = lines.next

      yield(lines.peek.chomp.gsub("\"", "")) if include_first_element

      loop do
        @batch_size.times { lines.next }
        yield(lines.peek.chomp.gsub("\"", ""))
      end
    rescue StopIteration
      nil
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
