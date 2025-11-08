require 'bundler/setup'
require 'language_operator'
require 'webmock/rspec'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end

WebMock.disable_net_connect!(allow_localhost: false)

def load_cron_tools
  registry = LanguageOperator::Dsl::Registry.new
  context = LanguageOperator::Dsl::Context.new(registry)
  tool_path = File.expand_path('../tools/cron.rb', __dir__)
  code = File.read(tool_path)
  context.instance_eval(code, tool_path)
  registry
end

RSpec.configure do |config|
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

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
