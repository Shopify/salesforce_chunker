require "test_helper"
require "httparty"

class BulkApiTest < Minitest::Test

  def test_check_response_error_raises_error
    assert_raises SalesforceChunker::ResponseError do
      SalesforceChunker::Connection.check_response_error(invalid_json_response)
    end
  end

  private

  def invalid_json_response
    {
      "exceptionCode"    => "InvalidRequest",
      "exceptionMessage" => "Request is invalid"
    }
  end
end
