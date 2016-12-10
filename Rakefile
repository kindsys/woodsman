require "bundler/gem_tasks"
require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec
task :test => :spec

desc "Specs"
RSpec::Core::RakeTask.new {}

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:junit) do |t|
  t.fail_on_error = false
  t.rspec_opts = "--no-drb -r rspec_junit_formatter --format RspecJunitFormatter -o test-reports/specs_junit.xml"
end
