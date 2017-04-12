# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'woodsman/version'

Gem::Specification.new do |spec|
  spec.name = 'woodsman'
  spec.version = Woodsman::VERSION
  spec.authors = ['GrowthHackers.com']
  spec.email = ['tech@growthhackers.com']
  spec.description = %q{Ruby logging utility.}
  spec.summary = %q{Woodsman is a logger that can wrap Rails.logger.}
  spec.homepage = 'https://growthhackers.com'
  spec.license = 'MIT'

  spec.files = Dir.glob('lib/**/*')
  spec.test_files = Dir.glob('{test,spec,features}/**/*')
  spec.executables = Dir.glob('bin/*').map { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '< 6'
  spec.add_dependency 'require_all', '~> 1.3'
  spec.add_dependency 'sentry-raven', '~> 2.3'

  spec.add_development_dependency 'guard-rspec', '~> 4.5'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.2'
  spec.add_development_dependency 'metric_fu', '~> 4.11'
  spec.add_development_dependency 'simplecov', '~> 0.9'
  spec.add_development_dependency 'webmock', '~> 1.18'
  spec.add_development_dependency 'timecop', '~> 0.7'
end
