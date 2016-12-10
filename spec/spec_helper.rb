require 'bundler/setup'
require 'benchmark'
require 'webmock/rspec'

Bundler.setup

# Need to start simplecov before including the gem
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start { add_filter 'spec/' }
end

require 'woodsman'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    # Disable the `should` old syntax for consistency.
    c.syntax = :expect
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.filter_run_excluding :slow unless ENV['SLOW_SPECS']
  config.profile_examples = 3
  config.order = 'random'

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end

RSpec::Matchers.define :having_number_of_lines_greater_than do |num_lines|
  match { |actual| actual.split("\n").count > num_lines }
end

RSpec::Matchers.define :having_number_of_lines_less_than do |num_lines|
  match { |actual| actual.split("\n").count < num_lines }
end