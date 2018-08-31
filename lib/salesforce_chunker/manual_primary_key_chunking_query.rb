module SalesforceChunker
  class PrimaryKeyChunkingQuery < Job

    def initialize(connection:, entity:, operation:, query:, **options)
      batch_size = options[:batch_size] || 100000

      super(connection: connection, entity: entity, operation: operation, **options)

      @initial_batch_id = nil

      ids = get_all_ids
      batches = split_ids_into_batches

      batches.each do |batch|
        query = generate_query(query, batch[0], batch[1])
        create_batch(query)
      end
    end

    def get_batch_statuses
      batches = super #remove initial batch id
    end


    def get_all_ids

    end

    def split_ids_into_batches(ids)

    end

    def generate_query(query, firstId, lastId)
    end
  end
end
