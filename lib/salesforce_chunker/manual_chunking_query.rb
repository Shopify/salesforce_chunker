module SalesforceChunker
  class ManualChunkingQuery < Job

    def initialize(connection:, object:, operation:, query:, **options)

      where_clause = self.class.query_where_clause(query)
      batch_size = options[:batch_size] || 100000

      #@log.info "Using Manual Chunking"
      #@log.info "Retrieving Ids from records"

      job = SalesforceChunker::SingleBatchJob.new(
        connection: connection,
        object: object,
        operation: operation,
        query: "Select Id From #{object} #{where_clause} Order By Id Asc",
        logger: options[:logger],
      )

      breakpoints = []

      job.download_results(retry_seconds: 10).with_index do |result, i|


        
        if i % batch_size == 0 && i != 0
          breakpoints << result["Id"]
        end
      end

      super(connection: connection, object: object, operation: operation, **options)

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
