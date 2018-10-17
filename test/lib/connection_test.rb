require "test_helper"
require "httparty"

class ConnectionTest < Minitest::Test

  def setup
    HTTParty.stubs(:post).returns(login_response)
    @connection = SalesforceChunker::Connection.new({})
    @connection.instance_variable_set(:@log, Logger.new(nil))
    HTTParty.unstub(:post)
  end

  def test_class_invoked
    refute_nil @connection
  end

  def test_error_raised_when_failure_response
    HTTParty.expects(:post).returns(login_response_fail)

    assert_raises SalesforceChunker::ConnectionError do
      SalesforceChunker::Connection.new({})
    end
  end

  def test_initialize_uses_correct_domain_and_version
    HTTParty.expects(:post).with("https://test.salesforce.com/services/Soap/u/37.0", anything).returns(login_response)
    SalesforceChunker::Connection.new(domain: "test", salesforce_version: "37.0")
  end

  def test_post_json_calls_post
    @connection.expects(:post).with("route", "{\"foo\":false}", {}).returns(true)
    assert @connection.post_json("route", {"foo": false})
  end


  def test_post_calls_post_with_correct_parameters
    expected_url = "https://na99.salesforce.com/services/async/42.0/route"
    expected_headers = {
      "Content-Type": "application/json",
      "X-SFDC-Session": "3ea96c71f254c3f2e6ce3a2b2b723c87",
      "Accept-Encoding": "gzip",
    }
    HTTParty.expects(:post).with(expected_url, body: "blah", headers: expected_headers).returns(json_response)

    response = @connection.post("/route", "blah")
    assert_equal 1234, response
  end

  def test_get_json_calls_get_with_correct_parameters
    expected_url = "https://na99.salesforce.com/services/async/42.0/getroute"
    expected_headers = {
      "Content-Type": "application/json",
      "X-SFDC-Session": "3ea96c71f254c3f2e6ce3a2b2b723c87",
      "Accept-Encoding": "gzip",
    }
    HTTParty.expects(:get).with(expected_url, headers: expected_headers).returns(json_response)

    response = @connection.get_json("/getroute")
    assert_equal 1234, response
  end

  def test_headers_can_be_overridden
    expected_url = "https://na99.salesforce.com/services/async/42.0/getroute"
    expected_headers = {
      "Content-Type": "text/csv",
      "X-SFDC-Session": "3ea96c71f254c3f2e6ce3a2b2b723c87",
      "Accept-Encoding": "gzip",
      "Foo": "bar",
    }
    HTTParty.expects(:get).with(expected_url, headers: expected_headers).returns(json_response)

    response = @connection.get_json("/getroute", {"Content-Type": "text/csv", "Foo": "bar"})
  end

  def test_get_instance_extracts_instance
    urls = [
      "https://na99.salesforce.com/something",
      "https://a.lot.of.dots.salesforce.com/something",
      "https://dots.and-dashes--.salesforce.com/something",
    ]

    expected_instances = [
      "na99",
      "a.lot.of.dots",
      "dots.and-dashes--",
    ]

    extracted_instances = urls.map { |url| SalesforceChunker::Connection.get_instance(url) }
    assert_equal expected_instances, extracted_instances
  end

  def test_check_response_error_raises_error
    assert_raises SalesforceChunker::ResponseError do
      SalesforceChunker::Connection.check_response_error(invalid_json_response)
    end
  end

  private

  def login_response
    parsed_response = mock()
    parsed_response.stubs(:parsed_response).returns({
      "Envelope" => {
        "Body" => {
          "loginResponse" => {
            "result" => {
              "sessionId" => "3ea96c71f254c3f2e6ce3a2b2b723c87",
              "serverUrl" => "https://na99.salesforce.com/something",
            }
          }
        }
      }
    })
    parsed_response
  end

  def login_response_fail
    parsed_response = mock()
    parsed_response.stubs(:parsed_response).returns({
      "Envelope" => {
        "Body" => {
          "Fault" => {
            "faultstring" => "An unexpected error occurred"
          }
        }
      }
    })
    parsed_response
  end

  def invalid_json_response
    {
      "exceptionCode"    => "InvalidRequest",
      "exceptionMessage" => "Request is invalid"
    }
  end

  def json_response
    parsed_response = mock()
    parsed_response.stubs(:parsed_response).returns(1234)
    parsed_response
  end
end
