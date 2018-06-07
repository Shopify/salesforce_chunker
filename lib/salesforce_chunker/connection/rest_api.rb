module SalesforceChunker
  class Connection::RestApi < SalesforceChunker::Connection

    def initialize(options)
      super

      url = "https://#{@options[:domain]}.salesforce.com/services/oauth2/token?grant_type=password&client_id=#{@options[:client_id]}&client_secret=#{@options[:client_secret]}&username=#{@options[:username]}&password=#{@options[:password]}#{@options[:security_token]}"
      response = HTTParty.post(url).parsed_response
      require 'pry'; binding.pry
    end
  end
end
