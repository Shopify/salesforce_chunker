require "salesforce_chunker/connection.rb"
require "salesforce_chunker/exceptions.rb"
require "salesforce_chunker/job.rb"
require "salesforce_chunker/single_batch_job.rb"
require "salesforce_chunker/primary_key_chunking_query.rb"
require 'logger'

module SalesforceChunker
  class Client

    def initialize(**options)
      @connection = SalesforceChunker::Connection.new(**options)
    end

    def query(query:, object:, **options)
      return to_enum(:query, query: query, object: object, **options) unless block_given?

      case options[:job_type]
      when "single_batch"
        job_class = SalesforceChunker::SingleBatchJob
      when "primary_key_chunking", nil # for backwards compatibility
        job_class = SalesforceChunker::PrimaryKeyChunkingQuery
      end

      job = job_class.new(
        connection: @connection,
        object: object,
        operation: "query",
        query: query,
        **options.slice(:batch_size, :logger, :log_output)
      )

      job.download_results(**options.slice(:timeout, :retry_seconds)) { |result| yield(result) }
    end

    def single_batch_query(**options)
      query(**options.merge(job_type: "single_batch"))
    end

    def primary_key_chunking_query(**options)
      query(**options.merge(job_type: "primary_key_chunking"))
    end
  end
end
