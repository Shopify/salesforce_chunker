module SalesforceChunker
  class Connection::RestApi < SalesforceChunker::Connection
    attr_reader :version

    def initialize(options)
      super
      url = "https://#{@options[:domain]}.salesforce.com/services/oauth2/token?grant_type=password&client_id=#{@options[:client_id]}&client_secret=#{@options[:client_secret]}&username=#{@options[:username]}&password=#{@options[:password]}#{@options[:security_token]}"
      response = HTTParty.post(url).parsed_response

      if response.is_a?(Hash) && response.key?("error")
        raise ConnectionError, response["error_description"]
      end

      @version = @options[:salesforce_version]
      @access_token = response["access_token"]
      @token_type = response["token_type"]
      @base_url = response["instance_url"]
      @default_headers = { "Content-Type": "application/json", "Authorization": "#{@token_type} #{@access_token}"}
    end
  end
end
