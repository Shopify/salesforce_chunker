require "httparty"

module SalesforceChunker
  class Connection

    def initialize(options)
      default_options = {
        salesforce_version: "42.0",
        host: "login.salesforce.com",
        username: "",
        password: "",
        security_token: "",
      }
      options = default_options.merge(options)

      url = "https://#{options[:host]}/services/Soap/u/#{options[:salesforce_version]}"
      headers = { "SOAPAction": "login", "Content-Type": "text/xml; charset=UTF-8" }

      login_soap_request_body = \
      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>
      <env:Envelope
              xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
              xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
              xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"
              xmlns:urn=\"urn:partner.soap.sforce.com\">
          <env:Body>
              <n1:login xmlns:n1=\"urn:partner.soap.sforce.com\">
                  <n1:username>#{options[:username].encode(xml: :text)}</n1:username>
                  <n1:password>#{options[:password].encode(xml: :text)}#{options[:security_token].encode(xml: :text)}</n1:password>
              </n1:login>
          </env:Body>
      </env:Envelope>"

      response = HTTParty.post(url, headers: headers, body: login_soap_request_body).parsed_response

      begin
        result = response["Envelope"]["Body"]["loginResponse"]["result"]
      rescue NoMethodError
        raise StandardError.new(response["Envelope"]["Body"]["Fault"]["faultstring"])
      end

      @base_url = "https://#{options[:host]}/services/async/#{options[:salesforce_version]}/"
      @default_headers = { "Content-Type": "application/json", "X-SFDC-Session": result["sessionId"] }
    end

    def post_json(url, body, headers={})
      HTTParty.post(@base_url + url, headers: headers.merge(@default_headers), body: body).parsed_response
    end

    def get_json(url, headers={})
      HTTParty.get(@base_url + url, headers: headers.merge(@default_headers)).parsed_response
    end
  end
end
