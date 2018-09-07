module SalesforceChunker
  class SingleBatchJob < Job
    def initialize(connection:, object:, operation:, **options)
      super(connection: connection, object: object, operation: operation, **options)
      payload = options[:payload] || options[:query]
      @log.info "Using Single Batch"
      @batch_id = create_batch(payload)
      @batches_count = 1
      close
    end
  end
end
