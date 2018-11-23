module SalesforceChunker
  class ManualChunkingQuery < Job

    def initialize(connection:, object:, operation:, query:, **options)
      @log = options.delete(:logger) || Logger.new(options[:log_output])
      @log.progname = "salesforce_chunker"
      batch_size = options[:batch_size] || 100000
      where_clause = self.class.query_where_clause(query)

      @log.info "Using Manual Chunking"
      breakpoint_creation_job = SalesforceChunker::ManualChunkingBreakpointQuery.new(
        connection: connection,
        object: object,
        operation: operation,
        logger: @log,
        batch_size: batch_size,
        query: "Select Id From #{object} #{where_clause} Order By Id Asc",
      )
      breakpoints = breakpoint_creation_job.download_results(retry_seconds: 10).to_a

      super(connection: connection, object: object, operation: operation, logger: @log, **options)

      @log.info "Creating Query Batches"
      create_batches(query, breakpoints, where_clause)

      close
    end

    def create_batches(query, breakpoints, where_clause)
      if breakpoints.empty?
        create_batch(query)
      else
        query += where_clause.empty? ? " Where" : " And"

        create_batch("#{query} Id < '#{breakpoints.first}'")
        breakpoints.each_cons(2) do |first, second|
          create_batch("#{query} Id >= '#{first}' And Id < '#{second}'")
        end
        create_batch("#{query} Id >= '#{breakpoints.last}'")
      end
      @batches_count = breakpoints.length + 1
    end

    def self.query_where_clause(query)
      query.partition(/where\s/i)[1..2].join
    end
  end
end
