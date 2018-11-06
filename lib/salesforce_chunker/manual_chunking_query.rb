module SalesforceChunker
  class ManualChunkingQuery < Job

    def initialize(connection:, object:, operation:, query:, **options)
      batch_size = options[:batch_size] || 100000
      where_clause = self.class.query_where_clause(query)

      super(connection: connection, object: object, operation: operation, **options)
      @log.info "Using Manual Chunking"

      @log.info "Retrieving Ids from records"
      breakpoints = breakpoints(object, where_clause, batch_size)

      @log.info "Creating Query Batches"
      create_batches(query, breakpoints, where_clause)

      close
    end

    def get_batch_statuses
      batches = super
      batches.delete_if { |batch| batch["id"] == @initial_batch_id && batches.count > 1 }
    end

    def breakpoints(object, where_clause, batch_size)
      @batches_count = 1
      @initial_batch_id = create_batch("Select Id From #{object} #{where_clause} Order By Id Asc")

      download_results(retry_seconds: 10)
        .with_index
        .select { |_, i| i % batch_size == 0 && i != 0 }
        .map { |result, _| result["Id"] }
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
