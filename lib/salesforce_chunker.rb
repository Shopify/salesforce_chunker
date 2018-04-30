require "salesforce_chunker/connection.rb"
require "salesforce_chunker/job.rb"

module SalesforceChunker
  class Client


    def initialize(username, password, security_token, sf_version="42.0", domain="test", retry_seconds=10)
      @connection = SalesforceChunker::Connection.new(username, password, security_token, sf_version, domain)
      @retry_seconds = retry_seconds
    end

    def query(soql="SELECT Name FROM Account", batch_size=1000, pk_chunking=true)

      job = SalesforceChunker::Job.new(@connection, soql, batch_size)

      # while true
      #   statuses = job.get_batch_statuses

      #   sleep(@retry_seconds)
      # end

      # retry loop every n seconds until all batches completed

        # job.get_batch_statuses

        # loop through all newly completed batches

          # loop through all results pages

            # loop through all results returned on a page

              # yield

      job.close
    end

    # private methods?

  end
end
