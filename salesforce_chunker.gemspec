
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "salesforce_chunker/version"

Gem::Specification.new do |spec|
  spec.name          = "salesforce_chunker"
  spec.version       = SalesforceChunker::VERSION
  spec.authors       = ["Curtis Holmes"]
  spec.email         = ["curtis.holmes@shopify.com"]

  spec.summary       = %q{Salesforce Bulk API Query Chunker Client}
  spec.description   = %q{Asynchronous and memory efficient Salesforce query downloading scalable to millions of items}
  spec.homepage      = 'https://github.com/Shopify/salesforce_chunker'
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.16.2"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "mocha", "~> 1.5.0"
end
