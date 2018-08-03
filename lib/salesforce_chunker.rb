require "salesforce_chunker/connection.rb"
require "salesforce_chunker/exceptions.rb"
require "salesforce_chunker/job.rb"
require "salesforce_chunker/primary_key_chunking_query.rb"
require 'logger'

module SalesforceChunker
  class Client

    def initialize(options)
      @connection = SalesforceChunker::Connection.new(options)
    end

    def query(query, entity, **options)
      raise StandardError, "No block given" unless block_given?

      job = SalesforceChunker::PrimaryKeyChunkingQuery.new(
        connection: @connection,
        entity: entity,
        operation: "query",
        query: query,
        batch_size: options[:batch_size],
        logger: options[:logger],
        log_output: options[:log_output],
      )

      download_options = {
        timeout: options[:timeout],
        retry_seconds: options[:retry_seconds],
      }

      job.download_results(**download_options) do |result|
        yield(result)
      end
    end
  end
end
