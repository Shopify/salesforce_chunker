module SalesforceChunker
  class SingleBatchJob < Job
    def initialize(connection:, entity:, operation:, payload:, **options)
      super(connection: connection, entity: entity, operation: operation, **options)
      @batch_id = create_batch(payload)
      @batches_count = 1
      close
    end
  end
end
