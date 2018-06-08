require "httparty"

module SalesforceChunker
  class Connection

    def initialize(options)
      default_options = {
        salesforce_version: "42.0",
        domain: "login",
        username: "",
        password: "",
        security_token: "",
      }

      @base_url = ""
      @default_headers = { "Content-Type": "application/json" }
      @options = default_options.merge(options)
    end

    def post_json(url, body, headers={})
      response = HTTParty.post(@base_url + url, headers: headers.merge(@default_headers), body: body).parsed_response
      self.class.check_response_error(response)
    end

    def get_json(url, headers={})
      response = HTTParty.get(@base_url + url, headers: headers.merge(@default_headers)).parsed_response
      self.class.check_response_error(response)
    end

    private

    def self.check_response_error(response)
      if response.is_a?(Hash) && response.key?("exceptionCode")
        raise ResponseError, "#{response["exceptionCode"]}: #{response["exceptionMessage"]}"
      else
        response
      end
    end
  end
end
