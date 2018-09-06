module SalesforceChunker
  class SingleBatchJob < Job
    def initialize(connection:, entity:, operation:, **options)
      super(connection: connection, entity: entity, operation: operation, **options)
      payload = options[:payload] || options[:query]
      @batch_id = create_batch(payload)
      @batches_count = 1
      close
    end
  end
end
