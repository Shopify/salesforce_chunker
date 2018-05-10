require "salesforce_chunker/connection.rb"
require "salesforce_chunker/job.rb"
require 'logger'

module SalesforceChunker
  class Client

    def initialize(options)
      @connection = SalesforceChunker::Connection.new(options)
    end

    def query(query, entity, **options)
      default_options = {
        batch_size: 100000,
        retry_seconds: 10,
      }
      options = default_options.merge(options)

      logger = options[:logger] || Logger.new(options[:log_output])
      tag = "[salesforce_chunker]"

      raise StandardError.new("no block given") unless block_given?

      logger.info("#{tag} Initializing Query")
      job = SalesforceChunker::Job.new(@connection, query, entity, options[:batch_size])
      retrieved_batches = []

      while true
        logger.info("#{tag} Retrieving batch status information")
        job.get_batch_statuses.each do |batch|
          next if retrieved_batches.include?(batch["id"])

          case batch["state"]
          when "Queued", "InProgress", "NotProcessed"
            next
          when "Completed"
            raise StandardError.new("records failed") if batch["numberRecordsFailed"] > 0
            if batch["numberRecordsProcessed"] > 0
              logger.info("#{tag} Batch #{retrieved_batches.length + 1} of #{job.batches_count || '?'}: #{batch["numberRecordsProcessed"]} records: retrieving")
              job.retrieve_batch_results(batch["id"]).each do |result_id|
                job.retrieve_results(batch["id"], result_id).each do |result|
                  result.tap { |h| h.delete("attributes") }
                  yield(result)
                end
              end
            else
              logger.info("#{tag} Batch #{retrieved_batches.length + 1} of #{job.batches_count}: 0 records: skipping")
            end
            retrieved_batches.append(batch["id"])
          when "Failed"
            raise StandardError.new("batch failed") # possibly get more information?
          end
        end

        break if job.batches_count && retrieved_batches.length == job.batches_count
        # timeout after some period?

        logger.info("#{tag} Waiting #{options[:retry_seconds]} seconds")
        sleep(options[:retry_seconds])
      end
    end
  end
end
