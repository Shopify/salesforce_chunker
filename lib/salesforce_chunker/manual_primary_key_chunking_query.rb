module SalesforceChunker
  class ManualPrimaryKeyChunkingQuery < Job

    def initialize(connection:, object:, operation:, **options)
      batch_size = options[:batch_size] || 100000
      @batch_ids_to_ignore = []

      super(connection: connection, object: object, operation: operation, **options)

      pods = get_min_max_for_each_pod(object)

      pods.each do |pod|
        #@log.info pod[0]
        #@log.info pod[1]

        min, max = pod

        min_decimal = SalesforceChunker::Base62.decode(min[6..14])
        max_decimal = SalesforceChunker::Base62.decode(max[6..14])

        difference = max_decimal - min_decimal

        first_six = min[0..5]

        @batches_count = 0

        10.times do |i|

          low = min_decimal + (i * (difference / 10))
          high = min_decimal + ((i+1) * (difference / 10))

          low_base62 = SalesforceChunker::Base62.encode(low)
          high_base62 = SalesforceChunker::Base62.encode(high)

          low_base62 = first_six + low_base62.rjust(9, '0')
          high_base62 = first_six + high_base62.rjust(9, '0')

          query = "Select Id From Account "
          if i == 0
            query += "where Id < '#{high_base62}'"
          elsif i == 9
            query += "where Id >= '#{low_base62}'"
          else
            query += "where Id >= '#{low_base62}' and Id < '#{high_base62}'"
          end

          @log.info query
          create_batch(query)
          @batches_count += 1
        end
      end


      # @initial_batch_id = nil

      # ids = get_all_ids(object)
      # batches = split_ids_into_batches

      # batches.each do |batch|
      #   query = generate_query(query, batch[0], batch[1])
      #   @log.info "Adding query: #{query}"
      #   create_batch(query)
      # end

      # @batches_count = batches.count
    end

    def split_up_batches


    end

    def get_min_max_for_each_pod(object)
      pod_min_maxes = []

      min_id = execute_query_and_get_single_result("Select Id From Account ORDER BY Id ASC LIMIT 1")
      max_id = execute_query_and_get_single_result("Select Id From Account ORDER BY Id DESC LIMIT 1")
      
      min_pod_id = min_id[3..4]
      max_pod_id = max_id[3..4]

      if min_pod_id == max_pod_id
        return [[min_id, max_id]]
      else
        
        first_three = min_id[0..2]

        loop do
          max_possible_lower_pod = "#{first_three}#{min_pod_id}0zzzzzzzzz"
          lower_pod_max_id = execute_query_and_get_single_result("Select Id From Account Where Id <= '#{max_possible_lower_pod}' ORDER BY Id DESC LIMIT 1")
          next_pod_min_id = execute_query_and_get_single_result("Select Id From Account Where Id > '#{max_possible_lower_pod}' ORDER BY Id ASC LIMIT 1")

          pod_min_maxes << [min_id, lower_pod_max_id]

          if next_pod_min_id[3..4] == max_pod_id
            pod_min_maxes << [next_pod_min_id, max_id]
            break
          end

          min_pod_id = next_pod_min_id[3..4]
          min_id = next_pod_min_id
        end

        
      end
      pod_min_maxes

      #max_query = 

      #min_query_id = 
      #max_query_id = create_batch(max_query)

      #result = []
      #job.get_batch_results(min_query_id) { |r| result << r["Id"] }
      #min_id = result[0]




    end

    def execute_query_and_get_single_result(query)
      @log.info query
      batch_id = create_batch(query)
      @batch_ids_to_ignore << batch_id
      result = []

      loop do
        case get_batch_statuses.select { |batch| batch["id"] == batch_id }[0]["state"]
        when "Completed"
          break
        when "Failed"
          raise "batch failed"
        else
          @log.info "sleeping 2 seconds"
          sleep 2
        end
      end

      get_batch_results(batch_id) { |r| result << r["Id"] }
      result[0]
    end

    def get_batch_statuses
      batches = super #remove initial batch id
      batches.delete_if { |batch| @batch_ids_to_ignore.include?(batch["Id"]) }
    end

    # def get_all_ids(object)
    #   @log.info "Getting all ids"
    #   query = "Select Id From #{object} Order By Id Asc"
    #   @batches_count = 1
    #   initial_batch_id = create_batch(query)
    #   #ids = []
    #   #download_results { |result| ids << result["Id"] }
      
    #   pods = {}

    #   download_results do |result|
    #     id = result["Id"]
    #     pod_id = id[3..4]
    #     pods[pod_id] = [] unless pods.has_key?(pod_id)
    #     pods[pod_id] << id
    #   end

    #   @initial_batch_id = initial_batch_id
    #   pods
    # end


    # def split_ids_into_batches(pods, batch_size)
    #   batches = []
    #   pods.each do |pod|
    #     pod.each_slice(batch_size) do |a| 
    #       batches << [a["Id"].first, a["Id"].last]
    #     end
    #   end
    #   batches
    # end

    # def generate_query(query, firstId, lastId)
    #   # need to detect wheres
    #   "#{query} Where Id >= #{firstId} And Id <= #{lastId}"
    # end
  end
end
