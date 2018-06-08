require "test_helper"
require "httparty"

class RestApiTest < Minitest::Test

  def setup
    HTTParty.stubs(:post).returns(login_response)
    @connection = SalesforceChunker::Connection::RestApi.new(
      client_id: "client123",
      client_secret: "secret123",
      salesforce_version: "41.0",
    )
    HTTParty.unstub(:post)
  end

  def test_error_raised_when_failure_response
    HTTParty.expects(:post).returns(login_response_fail)

    assert_raises SalesforceChunker::ConnectionError do
      SalesforceChunker::Connection::RestApi.new({})
    end
  end

  def test_initialize_uses_correct_credentials
    HTTParty.expects(:post).with("https://test.salesforce.com/services/oauth2/token?grant_type=password&client_id=client123&client_secret=secret123&username=test@shopify.com&password=abc123", anything).returns(login_response)
    SalesforceChunker::Connection::RestApi.new(
      username:       "test@shopify.com",
      password:       "abc",
      security_token: "123",
      client_id:      "client123",
      client_secret:  "secret123",
      domain: "test",
    )
  end

  def test_get_correct_version
    assert_equal "41.0", @connection.version
  end

  def test_get_json_calls_get_with_correct_parameters
    expected_url = "https://na99.salesforce.com/getroute"
    expected_headers = { "Content-Type": "application/json", "Authorization": "Bearer 1a2b3c4d5.e6f" }
    HTTParty.expects(:get).with(expected_url, headers: expected_headers).returns(json_response)

    response = @connection.get_json("/getroute")
    assert_equal 1234, response
  end

  private

  def login_response
    parsed_response = mock()
    parsed_response.stubs(:parsed_response).returns({
      "access_token" => "1a2b3c4d5.e6f",
      "instance_url" => "https://na99.salesforce.com",
      "id"           => "https://test.salesforce.com/something",
      "token_type"   => "Bearer",
      "issued_at"    => "1528472270562",
      "signature"    => "xyz890"
    })
    parsed_response
  end

  def login_response_fail
    parsed_response = mock()
    parsed_response.stubs(:parsed_response).returns({
      "error"             => "invalid_grant",
      "error_description" => "authentication failure",
    })
    parsed_response
  end

  def json_response
    parsed_response = mock()
    parsed_response.stubs(:parsed_response).returns(1234)
    parsed_response
  end
end
