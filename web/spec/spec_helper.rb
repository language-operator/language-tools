# frozen_string_literal: true

require 'bundler/setup'

# Start SimpleCov before loading application code
# require 'simplecov'
# SimpleCov.start do
#   add_filter '/spec/'
#   add_filter '/vendor/'
#
#   add_group 'Tools', 'tools'
#
#   minimum_coverage 80
#   minimum_coverage_by_file 70
# end

require 'language_operator'
require 'webmock/rspec'

# Configure WebMock to work with LanguageOperator::Dsl::HTTP
# The Language Operator DSL likely uses Net::HTTP under the hood
WebMock.disable_net_connect!(
  allow_localhost: false, 
  allow: [],
  net_http_connect_on_start: false
)

# Allow WebMock to stub all HTTP adapters including LanguageOperator::Dsl::HTTP
WebMock.enable!

# Additional configuration for stricter stubbing
WebMock::Config.instance.query_values_notation = :flat_array

RSpec.configure do |config|
  # Reset WebMock before each test to ensure clean state
  config.before(:each) do
    WebMock.reset!
    WebMock.enable!
    WebMock.disable_net_connect!(
      allow_localhost: false, 
      allow: [],
      net_http_connect_on_start: false
    )
  end

  # Ensure WebMock is properly cleaned up after each test
  config.after(:each) do
    # Check for unstubbed requests
    WebMock.reset!
  end
  
  # Add global stub checking
  config.around(:each) do |example|
    # Store original ENV
    original_env = ENV.to_h
    
    # Set ENV to ensure no real network calls
    ENV['WEBMOCK_DEBUG'] = 'true' if ENV['CI']
    
    begin
      example.run
    ensure
      # Restore original ENV
      ENV.replace(original_env)
    end
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end
