# SalesforceChunker

The `salesforce_chunker` gem is a simple ruby library to query the Salesforce Bulk API and download the results one batch at a time in a memory effiecent manner using a `yield` statement.

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
  username: "username",                 # required
  password: "password",                 # required
  security_token: "security_token",     # may be required depending on your Salesforce setup
  domain: "login",                      # optional: defaults to "login"
  salesforce_version: "42.0"            # optional: defaults to "42.0"
)
```

### Query

```ruby
query = "Select Name from Account" # required. SOQL query.
entity = "Account"                 # required. Sobject type.
options = {
  batch_size: 100000,              # optional: defaults to 100000. Number of records to process in a batch.
  retry_seconds: 10,               # optional: defaults to 10. Number of seconds to wait before querying API for updated results.
  timeout_seconds: 3600,           # optional: defaults to 3600. Number of seconds to wait before query is killed.
  logger: nil,                     # optional: logger to use. Must be similar to rails logger.
  log_output: nil,                 # optional: log output to use. i.e. STDOUT.
}

client.query(query, entity, options) do |result|
  process(result)
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/salesforce_chunker.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
