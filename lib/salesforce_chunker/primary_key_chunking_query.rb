module SalesforceChunker
  class PrimaryKeyChunkingQuery < Job

    def initialize(connection:, entity:, operation:, query:, **options)
      batch_size = options[:batch_size] || 100000

      if options[:headers].nil?
        options[:headers] = {"Sforce-Enable-PKChunking": "true; chunkSize=#{batch_size};" }
      else
        options[:headers].reverse_merge!({"Sforce-Enable-PKChunking": "true; chunkSize=#{batch_size};" })
      end

      super(connection: connection, entity: entity, operation: operation, **options)
      @initial_batch_id = create_batch(query)
    end

    def get_batch_statuses
      batches = super
      finalize_chunking_setup(batches) if @batches_count.nil?
      batches
    end

    private

    def finalize_chunking_setup(batches)
      initial_batch = batches.select { |batch| batch["id"] == @initial_batch_id }.first
      if initial_batch && initial_batch["state"] == "NotProcessed"
        @batches_count = batches.length - 1
        close
      end
    end
  end
end
