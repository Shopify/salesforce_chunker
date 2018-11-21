module SalesforceChunker
  class ManualChunkingBreakpointQuery < Job

    def initialize(connection:, object:, operation:, query:, **options)
       super(connection: connection, object: object, operation: operation, **options)
    end


    def get_batch_results(batch_id)
      retrieve_batch_results(batch_id).each do |result_id|
        results = retrieve_results(batch_id, result_id)
        # handle
      end
    end

    def create_job(object, options)
      body = {
        "operation": @operation,
        "object": object,
        "contentType": "CSV",
      }
      body[:externalIdFieldName] = options[:external_id] if @operation == "upsert"
      @connection.post_json("job", body, options[:headers].to_h)["id"]
    end
  end
end
