require "httparty"

module SalesforceChunker
  class Connection

    def initialize(username: "", password: "", security_token: "", domain: "login", salesforce_version: "42.0", **options)
      @log = options[:logger] || Logger.new(options[:log_output])
      @log.progname = "salesforce_chunker"

      response = HTTParty.post(
        "https://#{domain}.salesforce.com/services/Soap/u/#{salesforce_version}",
        headers: { "SOAPAction": "login", "Content-Type": "text/xml; charset=UTF-8" },
        body: self.class.login_soap_request_body(username, password, security_token)
      ).parsed_response

      result = response["Envelope"]["Body"]["loginResponse"]["result"]

      instance = self.class.get_instance(result["serverUrl"])

      @base_url = "https://#{instance}.salesforce.com/services/async/#{salesforce_version}/"
      @default_headers = {
        "Content-Type": "application/json",
        "X-SFDC-Session": result["sessionId"],
      }
    rescue NoMethodError
      raise ConnectionError, response["Envelope"]["Body"]["Fault"]["faultstring"]
    end

    def post_json(url, body, headers={})
      post(url, body.to_json, headers)
    end

    def post(url, body, headers={})
      @log.info "POST: #{url}"
      response = self.class.retry_block(log: @log) do
        HTTParty.post(@base_url + url, headers: @default_headers.merge(headers), body: body)
      end
      self.class.check_response_error(response.parsed_response)
    end

    def get_json(url, headers={})
      @log.info "GET: #{url}"
      response = self.class.retry_block(log: @log) do
        HTTParty.get(@base_url + url, headers: @default_headers.merge(headers))
      end
      self.class.check_response_error(response.parsed_response)
    end

    def get(url, headers={})
      @log.info "GET: #{url}"
      self.class.retry_block(log: @log) do
        HTTParty.get(@base_url + url, headers: @default_headers.merge(headers)).body
      end
    end

    private

    def self.login_soap_request_body(username, password, security_token)
      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>
      <env:Envelope
              xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
              xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
              xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"
              xmlns:urn=\"urn:partner.soap.sforce.com\">
          <env:Body>
              <n1:login xmlns:n1=\"urn:partner.soap.sforce.com\">
                  <n1:username>#{username.encode(xml: :text)}</n1:username>
                  <n1:password>#{password.encode(xml: :text)}#{security_token.encode(xml: :text)}</n1:password>
              </n1:login>
          </env:Body>
      </env:Envelope>"
    end

    def self.get_instance(server_url)
      /https:\/\/(.*).salesforce.com/.match(server_url)[1]
    end

    def self.check_response_error(response)
      if response.is_a?(Hash) && response.key?("exceptionCode")
        raise ResponseError, "#{response["exceptionCode"]}: #{response["exceptionMessage"]}"
      else
        response
      end
    end

    MAX_TRIES = 5
    SLEEP_DURATION = 10
    RESCUED_EXCEPTIONS = [Net::ReadTimeout, IOError]

    def self.retry_block(log: Logger.new(nil), tries: MAX_TRIES, sleep_duration: SLEEP_DURATION, rescues: RESCUED_EXCEPTIONS, &block)
      attempt_number = 1

      begin
        return block.call
      rescue *rescues => e
        log.warn "Retry block attempt #{attempt_number} rescued exception: #{e}"
        if attempt_number >= tries
          log.error "Maximum number of tries (#{tries}) was reached in retry_block. Raising exception."
          raise e
        else
          attempt_number += 1
          sleep sleep_duration
          retry
        end
      end
    end
  end
end
