# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'woodsman/version'

Gem::Specification.new do |spec|
  spec.name = 'woodsman'
  spec.version = Woodsman::VERSION
  spec.authors = ['Kind Systems']
  spec.email = ['oss@kindsys.us']
  spec.description = %q{Ruby logging utility.}
  spec.summary = %q{Woodsman is a logger that can wrap Rails.logger.}
  spec.homepage = 'https://kindness.dev'
  spec.license = 'MIT'

  spec.files = Dir.glob('lib/**/*')
  spec.test_files = Dir.glob('{test,spec,features}/**/*')
  spec.executables = Dir.glob('bin/*').map { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 7.0'
  spec.add_dependency 'require_all', '~> 3.0'
  spec.add_dependency 'sentry-ruby', '~> 4.4'

  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.4'
  spec.add_development_dependency 'metric_fu', '~> 4.13'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.add_development_dependency 'webmock', '~> 3.12'
  spec.add_development_dependency 'timecop', '~> 0.9'
end
