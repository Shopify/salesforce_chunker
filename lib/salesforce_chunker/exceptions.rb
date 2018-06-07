module SalesforceChunker
  class Error < StandardError; end

  # Raised when connecting with Salesforce fails
  class ConnectionError < Error; end

  # Raised when a request sent to Salesforce is invalid
  class ResponseError < Error; end

  # Raised when Salesforce returns a failed batch
  class BatchError < Error; end

  # Raised when Salesforce returns a successful batch with failed record(s)
  class RecordError < Error; end

  # Raised when batch job exceeds time limit
  class TimeoutError < Error; end
end
