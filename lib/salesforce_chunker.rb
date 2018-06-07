require "salesforce_chunker/connection.rb"
require "salesforce_chunker/connection/bulk_api.rb"
require "salesforce_chunker/exceptions.rb"
require "salesforce_chunker/job.rb"
require 'logger'

module SalesforceChunker
  class Client

    def initialize(options, bulk=true)
      if bulk
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

      logger = options[:logger] || Logger.new(options[:log_output])
      tag = "[salesforce_chunker]"

      raise StandardError, "No block given" unless block_given?

      start_time = Time.now.to_i
      logger.info("#{tag} Initializing Query")
      job = SalesforceChunker::Job.new(@connection, query, entity, options[:batch_size])
      retrieved_batches = []

      loop do
        logger.info("#{tag} Retrieving batch status information")
        job.get_batch_statuses.each do |batch|
          next if retrieved_batches.include?(batch["id"])

          case batch["state"]
          when "Queued", "InProgress", "NotProcessed"
            next
          when "Completed"
            raise RecordError, "Failed records in batch" if batch["numberRecordsFailed"] > 0

            logger.info("#{tag} Batch #{retrieved_batches.length + 1} of #{job.batches_count || '?'}: " \
              "retrieving #{batch["numberRecordsProcessed"]} records")
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

        logger.info("#{tag} Waiting #{options[:retry_seconds]} seconds")
        sleep(options[:retry_seconds])
      end

      logger.info("#{tag} Completed")
    end
  end
end
