require "test_helper"
require "httparty"

class ConnectionTest < Minitest::Test

  def setup
    HTTParty.stubs(:post).returns(login_response)
    @connection = SalesforceChunker::Connection.new({})
    HTTParty.unstub(:post)
  end

  def test_class_invoked
    refute_nil @connection
  end

  def test_error_raised_when_failure_response
    HTTParty.expects(:post).returns(login_response_fail)

    assert_raises StandardError do
      SalesforceChunker::Connection.new({})
    end
  end

  def test_initialize_uses_correct_domain_and_version
    HTTParty.expects(:post).with("https://test.salesforce.com/services/Soap/u/37.0", anything).returns(login_response)
    SalesforceChunker::Connection.new(domain: "test", salesforce_version: "37.0")
  end

  def test_post_json_calls_post_with_correct_parameters
    expected_url = "https://na99.salesforce.com/services/async/42.0/route"
    expected_headers = { "Content-Type": "application/json", "X-SFDC-Session": "3ea96c71f254c3f2e6ce3a2b2b723c87" }
    HTTParty.expects(:post).with(expected_url, body: {"blah": true}, headers: expected_headers).returns(json_response)

    response = @connection.post_json("route", {"blah": true})
    assert_equal 1234, response
  end

  def test_get_json_calls_get_with_correct_parameters
    expected_url = "https://na99.salesforce.com/services/async/42.0/getroute"
    expected_headers = { "Content-Type": "application/json", "X-SFDC-Session": "3ea96c71f254c3f2e6ce3a2b2b723c87" }
    HTTParty.expects(:get).with(expected_url, headers: expected_headers).returns(json_response)

    response = @connection.get_json("getroute")
    assert_equal 1234, response
  end

  def test_get_instance_extracts_instance
    assert_equal "na99", SalesforceChunker::Connection.get_instance("https://na99.salesforce.com/something")
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

  def json_response
    parsed_response = mock()
    parsed_response.stubs(:parsed_response).returns(1234)
    parsed_response
  end
end
