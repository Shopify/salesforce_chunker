# SalesforceChunker

The `salesforce_chunker` gem is a simple ruby library to query the Salesforce Bulk API and download the results one batch at a time in a memory effiecent manner using a `yield` statement. It uses [Primary Key Chunking](https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/async_api_headers_enable_pk_chunking.htm) to split large queries into batches and downloads each batch separately.

Currently, only `query` is available.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'salesforce_chunker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install salesforce_chunker

## Usage

### Simple Example

```ruby
client = SalesforceChunker::Client.new(
  username: "username", 
  password: "password", 
  security_token: "security_token",
)

client.query("Select Name From Account", "Account") { |result| process(result) }
```

### Initialize

```ruby
client = SalesforceChunker::Client.new(
  username:             "username",
  password:             "password",
  security_token:       "security_token",
  domain:               "login",
  salesforce_version:   "42.0",
)
```

| Parameter | |
| --- | --- |
| username | required |
| password | required |
| security_token | may be required depending on your Salesforce setup |
| domain | optional. defaults to `"login"`. |
| salesforce_version | optional. defaults to `"42.0"`. Must be >= `"33.0"` to use PK Chunking. |

### Query

```ruby
query = "Select Name from Account" # required. SOQL query.
entity = "Account"                 # required. Sobject type.
options = {
  batch_size:       100000,              
  retry_seconds:    10,               
  timeout_seconds:  3600,           
  logger:           nil,                     
  log_output:       STDOUT,                 
}

client.query(query, entity, options) do |result|
  process(result)
end
```

| Parameter | |
| --- | --- |
| batch_size | optional. defaults to `100000`. Number of records to process in a batch. |
| retry_seconds | optional. defaults to `10`. Number of seconds to wait before querying API for updated results. |
| timeout_seconds | optional. defaults to `3600`. Number of seconds to wait before query is killed. |
| logger | optional. logger to use. Must be instance of or similar to rails logger. |
| log_output | optional. log output to use. i.e. `STDOUT`. |

## Development

After checking out the repo, 
- run `bin/setup` to install dependencies. 
- run `rake test` to run the tests.
- run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/salesforce_chunker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
