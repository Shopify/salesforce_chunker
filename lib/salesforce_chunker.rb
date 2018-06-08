require "salesforce_chunker/connection.rb"
require "salesforce_chunker/connection/bulk_api.rb"
require "salesforce_chunker/connection/rest_api.rb"
require "salesforce_chunker/exceptions.rb"
require "salesforce_chunker/job.rb"
require 'logger'

module SalesforceChunker
  class Client

    def initialize(options, bulk=true)
      @bulk = bulk

      if @bulk
        @connection = SalesforceChunker::Connection::BulkApi.new(options)
      else
        @connection = SalesforceChunker::Connection::RestApi.new(options)
      end
    end

    def query(query, entity, **options)
      default_options = {
        batch_size: 100000,
        retry_seconds: 10,
        timeout_seconds: 3600,
      }
      options = default_options.merge(options)

      @logger = options[:logger] || Logger.new(options[:log_output])

      raise StandardError, "No block given" unless block_given?

      log "Initializing query"

      if @bulk
        bulk_query(query, entity, options) do |result|
          yield(result)
        end
      else
        rest_query(query) do |result|
          yield(result)
        end
      end

      log "Completed"
    end

    private

    def log(message)
      tag = "[salesforce_chunker]"
      @logger.info("#{tag} #{message}")
    end

    def rest_query(query)
      has_more = true
      query = query.squish.gsub("+", "%2B")
      url = "/services/data/v#{@connection.version}/query/?q=#{query}"

      rows = 0
      while has_more
        response = @connection.get_json(url)

        if response.is_a?(Array) && response.first.key?("errorCode")
          response = response.first
          raise ResponseError, "#{response["errorCode"]}: #{response["message"]}"
        else
          results = response["records"]
        end

        results.each do |result|
          rows += 1
          yield(result)
        end

        if !response["done"]
          url = response["nextRecordsUrl"]
        else
          has_more = false
        end

        log "Extracted #{rows} out of #{response["totalSize"]} records"
      end
    end

    def bulk_query(query, entity, options)
      start_time = Time.now.to_i
      job = SalesforceChunker::Job.new(@connection, query, entity, options[:batch_size])
      retrieved_batches = []

      loop do
        log "Retrieving batch status information"

        job.get_batch_statuses.each do |batch|
          next if retrieved_batches.include?(batch["id"])

          case batch["state"]
          when "Queued", "InProgress", "NotProcessed"
            next
          when "Completed"
            raise RecordError, "Failed records in batch" if batch["numberRecordsFailed"] > 0

            log "Batch #{retrieved_batches.length + 1} of #{job.batches_count || '?'}: retrieving #{batch["numberRecordsProcessed"]} records"
            if batch["numberRecordsProcessed"] > 0
              job.get_batch_results(batch["id"]) do |result|
                yield(result)
              end
            end
            retrieved_batches.append(batch["id"])
          when "Failed"
            raise BatchError, "Batch failed: #{batch["stateMessage"]}"
          end
        end

        break if job.batches_count && retrieved_batches.length == job.batches_count
        raise TimeoutError, "Timeout during batch processing" if (Time.now.to_i - start_time) > options[:timeout_seconds]

        log "Waiting #{options[:retry_seconds]} seconds"
        sleep(options[:retry_seconds])
      end
    end
  end
end
