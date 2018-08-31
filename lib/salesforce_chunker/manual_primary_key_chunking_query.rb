module SalesforceChunker
  class ManualPrimaryKeyChunkingQuery < Job

    def initialize(connection:, entity:, operation:, query:, **options)
      batch_size = options[:batch_size] || 100000

      super(connection: connection, entity: entity, operation: operation, **options)

      @initial_batch_id = nil

      ids = get_all_ids(entity)
      batches = split_ids_into_batches

      batches.each do |batch|
        query = generate_query(query, batch[0], batch[1])
        @log.info "Adding query: #{query}"
        create_batch(query)
      end

      @batches_count = batches.count
    end

    def get_batch_statuses
      batches = super #remove initial batch id

      batches.select do |batch|
        batch["Id"] != @initial_batch_id
      end
    end

    def get_all_ids(entity)
      @log.info "Getting all ids"
      query = "Select Id From #{entity} Order By Id Asc"
      @batches_count = 1
      initial_batch_id = create_batch(query)
      #ids = []
      #download_results { |result| ids << result["Id"] }
      
      pods = {}

      download_results do |result|
        id = result["Id"]
        pod_id = id[3..4]
        pods[pod_id] = [] unless pods.has_key?(pod_id)
        pods[pod_id] << id
      end

      @initial_batch_id = initial_batch_id
      pods
    end


    def split_ids_into_batches(pods, batch_size)
      batches = []
      pods.each do |pod|
        pod.each_slice(batch_size) do |a| 
          batches << [a["Id"].first, a["Id"].last]
        end
      end
      batches
    end

    def generate_query(query, firstId, lastId)
      # need to detect wheres
      "#{query} Where Id >= #{firstId} And Id <= #{lastId}"
    end
  end
end
