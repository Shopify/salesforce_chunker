require "salesforce_chunker/connection.rb"
require "salesforce_chunker/exceptions.rb"
require "salesforce_chunker/job.rb"
require "salesforce_chunker/single_batch_job.rb"
require "salesforce_chunker/primary_key_chunking_query.rb"
require "salesforce_chunker/manual_chunking_query.rb"
require "salesforce_chunker/manual_chunking_breakpoint_query.rb"
require 'logger'

module SalesforceChunker
  class Client

    def initialize(**options)
      @log = options[:logger] || Logger.new(options[:log_output])
      @log.progname = "salesforce_chunker"

      @connection = SalesforceChunker::Connection.new(**options, logger: @log)
    end

    def query(query:, object:, **options)
      return to_enum(:query, query: query, object: object, **options) unless block_given?

      case options[:job_type]
      when "single_batch"
        job_class = SalesforceChunker::SingleBatchJob
      when "manual_chunking"
        job_class = SalesforceChunker::ManualChunkingQuery
      when "primary_key_chunking", nil # for backwards compatibility
        job_class = SalesforceChunker::PrimaryKeyChunkingQuery
      end

      operation = options[:include_deleted] ? "queryAll" : "query"

      job_params = {
        connection: @connection,
        object: object,
        operation: operation,
        query: query,
        **options.slice(:batch_size, :logger, :log_output)
      }
      job_params[:logger] = @log if job_params[:logger].nil? && job_params[:log_output].nil?

      job = job_class.new(**job_params)
      job.download_results(**options.slice(:timeout_seconds, :retry_seconds)) { |result| yield(result) }
    end

    def single_batch_query(**options)
      query(**options.merge(job_type: "single_batch"))
    end

    def primary_key_chunking_query(**options)
      query(**options.merge(job_type: "primary_key_chunking"))
    end

    def manual_chunking_query(**options)
      query(**options.merge(job_type: "manual_chunking"))
    end
  end
end
