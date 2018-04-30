require "httparty"
# require "pry"

module SalesforceChunker
  class Connection

    def initialize(username, password, security_token, sf_version="42.0", domain="test")
      @sf_version = sf_version

      url = "https://#{domain}.salesforce.com/services/Soap/u/#{sf_version}"
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
                  <n1:username>#{username}</n1:username>
                  <n1:password>#{password}#{security_token}</n1:password>
              </n1:login>
          </env:Body>
      </env:Envelope>"

      response = HTTParty.post(url, headers: headers, body: login_soap_request_body)
      result = response.parsed_response["Envelope"]["Body"]["loginResponse"]["result"]

      @session_id = result["sessionId"]
      @instance = get_instance(result["serverUrl"])
      @server_url = result["serverUrl"]
    end

    def post_json(url, body, headers={})
      url = "https://#{@instance}.salesforce.com/services/async/#{@sf_version}/" + url
      headers = headers.merge({ "Content-Type": "application/json", "X-SFDC-Session": @session_id})
      HTTParty.post(url, headers: headers, body: body).parsed_response
    end

    def get_json(url, headers={})
      url = "https://#{@instance}.salesforce.com/services/async/#{@sf_version}/" + url
      headers = headers.merge({ "Content-Type": "application/json", "X-SFDC-Session": @session_id})
      HTTParty.get(url, headers: headers).parsed_response
    end

    # private

    def get_instance(server_url)
      # this may not be very robust 
      /[a-z0-9]+.salesforce/.match(server_url)[0].split(".")[0]
    end
  end
end