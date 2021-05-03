# Woodsman

Ruby logging utility gem.

## Installation

Add this line to your application's Gemfile:

    gem 'woodsman'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install woodsman

## Usage

### Woodsman.Logger
Simple but complete logger that can sit on top of Rails logger. You can use from a global reference via
Woodsman.logger.XXX. For Rails, you will need to make the following config changes to hook into initialization and wrap
the Rails logger will be available for controllers, models, and tests.

config/application.rb:
  config.action_controller.logger = Woodsman.logger = Woodsman::Logger.new(Logger.new(STDOUT))

config/initializers/init_woodsman_logger.rb:
  Rails.logger = Woodsman::Logger.new(Rails.logger) # Normal Rails logger. For tests, logs will end up in logs/test.log
  # Or you can alternatively use the lighter weight version that outputs to the console if you prefer for your tests:
  #Rails.logger = Woodsman.logger = Woodsman::Logger.new(Logger.new(STDOUT))

### Scrubber Stack
Scrubbers are used by the logger to strike-out and/or silence un-wanted logging. We construct a default scrubber stack
that includes silencing of health checks that pass, as that is fairly noisy if configured on a 1 minute interval.

#### Scrubber
A scrubber must respond to the following:
  name: returns the name of the scrubber
  scrub_block: returns a lambda that scrubs a single line. The lambda will get line and context as inputs. The line is
  a string representing the line that will be logged. The context is a hash of key/value pairs representing the current 
  logger context. The lambda must return the scrubbed line. If a nil is returned as the scrubbed line, then the logger  
  will silence the line and not log anything at all.

### Insecure and Secure Data Hash Utilities

    merged_hash = Woodsman.merge_hash(h1, h2)

  This is meant to merge hashes split apart using the spit_hash method. It will perform a deep merge, recursively merging
  data at the key level. For array values, it will do an index-based merge.
  
  The standard call pattern is to have one representing secure data, which is stored encrypted at-rest, and the other 
  representing insecure data, which is not encrypted. Since we are following the semantics of merge, h2's values will typically override h1 values.

    matching, remainder = Woodsman.split_hash(source, split_map)
    
  This is used to split secure data out of an existing hash (i.e. the bureau report subset or lead data_hash). The return value
  is a hash representing the data that matched the split_map and a remainder hash, which represents the non-matched data.
  These can be passed back in to the merge_hash to get a hash equivalent to the source.
  
  The split_map is a hash structure that mimics the structure of the matching data. So you if you want to match a key
  called ssn, the split_map would be as follows: {ssn: 1}. The value is not relevant currently but may be used for expansion
  in the future - it is recommended to set the value to either true or 1 for now. To split a nested value, a corresponding
  nesting is necessary. For example, {primary_applicant: {ssn: 1}} would reach into the primary_applicant and split out the
  SSN. Finally, to support collections of objects represented by an array containing hashes, the following format will split
  out the SSN of many applicants: {applicant: [{ssn:1}]}