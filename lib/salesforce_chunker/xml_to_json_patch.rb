module SalesforceChunker
  module XMLToJSONPatch

    def self.create_batch(response)
      response["batchInfo"]
    end

    def self.get_batch_statuses(response)
      if response["batchInfoList"]["batchInfo"].is_a? Array
        response["batchInfoList"]
      else
        {"batchInfo" => [response["batchInfoList"]["batchInfo"]]}
      end
    end

    def self.retrieve_batch_results(response)
      if response["result_list"]["result"].is_a? Array
        response["result_list"]["result"]
      else
        [response["result_list"]["result"]]
      end
    end

    def self.apply(type, url, response)
      case url
      when /job\/([a-zA-Z0-9])+\/batch\/*$/
        if type.downcase == "post"
          create_batch(response)
        else
          get_batch_statuses(response)
        end
      when /job\/([a-zA-Z0-9])+\/batch\/([a-zA-Z0-9])+\/result\/*$/
        retrieve_batch_results(response) 
      else
        response
      end
    end
  end
end
