# SalesforceChunker

The `salesforce_chunker` gem is a ruby library for interacting with the Salesforce Bulk API. It was primarily designed as an extractor to handle queries using batching and [Primary Key Chunking](https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/async_api_headers_enable_pk_chunking.htm). 

Currently, only querying is built into `SalesforceChunker::Client`, but non-query jobs can be created with `SalesforceChunker::Job`.

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

### SalesforceChunker::Client

#### Simple Example

```ruby
client = SalesforceChunker::Client.new(
  username: "username", 
  password: "password", 
  security_token: "security_token",
)

client.query("Select Name From Account", "Account") { |result| process(result) }
```

#### Initialize

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

#### Functions

| function | |
| --- | --- |
| query |
| single_batch_query | calls `query(job_type: "single_batch", **options)`  |
| primary_key_chunking_query | calls `query(job_type: "primary_key_chunking", **options)` |

#### Query

```ruby
query = "Select Name from Account" # required. SOQL query.
object = "Account"                 # required. Salesforce object type.
options = {
  batch_size:       100000,              
  retry_seconds:    10,               
  timeout_seconds:  3600,           
  logger:           nil,                     
  log_output:       STDOUT,
  job_type:         "primary_key_chunking",
}

client.query(query, object, options) do |result|
  process(result)
end
```

| Parameter | |
| --- | --- |
| batch_size | optional. defaults to `100000`. Number of records to process in a batch. (Only for PK Chunking) |
| retry_seconds | optional. defaults to `10`. Number of seconds to wait before querying API for updated results. |
| timeout_seconds | optional. defaults to `3600`. Number of seconds to wait before query is killed. |
| logger | optional. logger to use. Must be instance of or similar to rails logger. |
| log_output | optional. log output to use. i.e. `STDOUT`. |
| job_type | optional. defaults to `"primary_key_chunking"`. Can also be set to `"single_batch"`. | 

`query` can either be called with a block, or will return an enumerator:

```ruby
names = client.query(query, object, options).map { |result| result["Name"] }
```

### Under the hood: SalesforceChunker::Job

Using `SalesforceChunker::Job`, you have more direct access to the Salesforce Bulk API functions, such as `create_batch`, `get_batch_statuses`, and `retrieve_batch_results`. This can be used to perform custom tasks, such as upserts or multiple batch queries.

This should be used in coordination with `SalesforceChunker::Connection`, which has the same initialization process as `SalesforceChunker::Client`.

## Development

After checking out the repo, 
- run `bin/setup` to install dependencies. 
- run `rake test` to run the tests.
- run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/salesforce_chunker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
