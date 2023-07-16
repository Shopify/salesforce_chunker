
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "salesforce_chunker/version"

Gem::Specification.new do |spec|
  spec.name          = "salesforce_chunker"
  spec.version       = SalesforceChunker::VERSION
  spec.authors       = ["Curtis Holmes"]
  spec.email         = ["curtis.holmes@shopify.com"]

  spec.summary       = %q{Salesforce Bulk API Client}
  spec.description   = %q{Salesforce client and extractor designed for handling large amounts of data}
  spec.homepage      = 'https://github.com/Shopify/salesforce_chunker'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.15"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "mocha", "~> 1.5"
  spec.add_development_dependency "pry", "~> 0.11"
end
