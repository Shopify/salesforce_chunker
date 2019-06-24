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

names = client.query(query: "Select Name From User", object: "User").map { |result| result["Name"] }
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
| manual_chunking_query | calls `query(job_type: "manual_chunking", **options)` |

#### Query

```ruby
options = {
  query:            "Select Name from Account",
  object:           "Account",
  batch_size:       100000,
  retry_seconds:    10,
  timeout_seconds:  3600,
  logger:           nil,
  log_output:       STDOUT,
  job_type:         "primary_key_chunking",
  include_deleted:  true,
}

client.query(options) do |result|
  process(result)
end
```

| Parameter | | |
| --- | --- | --- |
| query | required | SOQL query. |
| object | required | Salesforce Object type. |
| batch_size | optional | defaults to `100000`. Number of records to process in a batch. (Not used in Single Batch jobs) |
| retry_seconds | optional | defaults to `10`. Number of seconds to wait before querying API for updated results. |
| timeout_seconds | optional | defaults to `3600`. Number of seconds to wait for a batch to process before job is killed. |
| logger | optional | logger to use. Must be instance of or similar to rails logger. |
| log_output | optional | log output to use. i.e. `STDOUT`. |
| job_type | optional | defaults to `"primary_key_chunking"`. Can also be set to `"single_batch"` or `"manual_chunking`. |
| include_deleted | optional | defaults to `false`. Whether to include deleted records. |

`query` can either be called with a block, or will return an enumerator:

```ruby
names = client.query(query, object, options).map { |result| result["Name"] }
```

### A discussion about Single Batch, Primary Key Chunking, and Manual Chunking job types.

One of the advantages of the Salesforce Bulk API over the other Salesforce APIs is the ability for Salesforce to process a number of requests (either queries or uploads) in parallel on their servers. The request chunks are referred to as batches.

#### Single Batch Query

In a single batch query, one SOQL statement is executed as a single batch. This works best if the total number of records to return is fewer than around 100,000 depending on memory usage and the number of fields being returned.

#### Primary Key Chunking Query

In Primary Key Chunking, the internal Salesforce PK chunking flag is used. Salesforce will create a number of batches automatically based on an internal Id index. See https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/async_api_headers_enable_pk_chunking.htm

#### Manual Chunking Query

This approach is called "Manual" Chunking because it is our own implementation of PK Chunking in this gem. The gem downloads a CSV ordered list of all Ids it needs to download, and then uses this list to generate breakpoints that it uses to create batches.

#### Primary Key Chunking Query vs Manual Chunking Query

Advantages of Manual Chunking:

- Manual Chunking takes into account the where clause in the SOQL statement. For example, if you are filtering a small number of a large object count, say 250k out of 20M Objects, then Manual Chunking will split this into 3 batches of max 100k while PK chunking will split this into 200 batches, which will use up batches and API requests against your account and take a longer amount of time.
- Any object can use Manual Chunking (according to Salesforce, PK chunking is supported for the following objects: Account, Asset, Campaign, CampaignMember, Case, CaseHistory, Contact, Event, EventRelation, Lead, LoginHistory, Opportunity, Task, User, and custom objects.)

Advantages of Primary Key Chunking:

- Primary Key Chunking appears to be slightly faster, if using a PK Chunking eligible object and no where clause.
- Primary Key Chunking may be less buggy because many more people depend on the Salesforce API than this gem.

### Under the hood: SalesforceChunker::Job

Using `SalesforceChunker::Job`, you have more direct access to the Salesforce Bulk API functions, such as `create_batch`, `get_batch_statuses`, and `retrieve_batch_results`. This can be used to perform custom tasks, such as upserts or multiple batch queries.

This should be used in coordination with `SalesforceChunker::Connection`, which has the same initialization process as `SalesforceChunker::Client`.

```ruby
connection = SalesforceChunker::Connection.new(
  username: "username",
  password: "password",
  security_token: "security_token",
)

job = SalesforceChunker::Job.new(
  connection: connection,
  object: "Account",
  operation: "query",
  log_output: STDOUT,
)

job.create_batch("Select Id From Account Order By Id Desc Limit 1")
job.create_batch("Select Id From Account Order By Id Asc Limit 1")
job.close

job.instance_variable_set(:@batches_count, 2)
ids = job.download_results.to_a
```

Also, `SalesforceChunker::SingleBatchJob` can be used to create a Job with only a single batch. This automatically handles the batch creation, closing, and setting `@batches_count`.

```ruby
job = SalesforceChunker::SingleBatchJob.new(
  connection: connection,
  object: "Account",
  operation: "upsert",
  payload: [{ "Name" => "Random Account", "IdField__c" => "123456" }],
  external_id: "IdField__c",
  log_output: STDOUT,
)

loop do
  batch = job.get_batch_statuses.first
  if batch["state"] == "Completed"
    break
  elsif batch["state"] == "Failed"
    raise "batch failed"
  end
  sleep 5
end
```

## Development

After checking out the repo, 
- run `bin/setup` to install dependencies. 
- run `rake test` to run the tests.
- run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/salesforce_chunker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
