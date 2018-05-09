require "salesforce_chunker/connection.rb"
require "salesforce_chunker/job.rb"

module SalesforceChunker
  class Client

    def initialize(username, password, security_token, domain="test", sf_version="42.0", retry_seconds=10)
      @connection = SalesforceChunker::Connection.new(username, password, security_token, domain, sf_version)
      @retry_seconds = retry_seconds
    end

    def query(soql="SELECT Name FROM Account", batch_size=10000)

      raise StandardError.new("no block given") unless block_given?

      job = SalesforceChunker::Job.new(@connection, soql, batch_size)
      retrieved_batches = []

      while true
        job.get_batch_statuses.each do |batch|
          next if retrieved_batches.include?(batch["id"])

          case batch["state"]
          when "Queued", "InProgress", "NotProcessed"
            next
          when "Completed"
            raise StandardError.new("records failed") if batch["numberRecordsFailed"] > 0
            if batch["numberRecordsProcessed"] > 0
              job.retrieve_batch_results(batch["id"]).each do |result_id|
                job.retrieve_results(batch["id"], result_id).each do |result|
                  result.tap { |h| h.delete("attributes") }
                  yield(result)
                end
              end
            end
            retrieved_batches.append(batch["id"])
          when "Failed"
            raise StandardError.new("batch failed") # possibly get more information?
          end
        end

        break if job.batches_count && retrieved_batches.length == job.batches_count
        # timeout after some period?
        sleep(@retry_seconds)
      end
    end
  end
end
