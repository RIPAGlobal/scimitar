# ============================================================================
# PREAMBLE
# ============================================================================

# Get code coverage reports:
#
# https://github.com/colszowka/simplecov#getting-started
#
# "Load and launch SimpleCov at the very top of your test/test_helper.rb (or
#  spec_helper.rb [...])"
#
require 'simplecov'
SimpleCov.start 'rails'

# Rails stuff is related to the self-test applications in 'spec/apps'.
#
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../apps/dummy/config/environment', __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'byebug'
require 'scimitar'

# ============================================================================
# MAIN RSPEC CONFIGURATION
# ============================================================================

RSpec.configure do | config |
  config.disable_monkey_patching!
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.color                      = true
  config.tty                        = true
  config.order                      = :random
  config.fixture_path               = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true

  Kernel.srand config.seed
end

# ============================================================================
# MISCELLANEOUS UTILITIES
# ============================================================================

# Capture stdout from running a given block.
#
def spec_helper_capture_stdout( &block )
  result = ''

  begin
    old_stdout = $stdout
    $stdout = StringIO.new

    yield

    result = $stdout.string

  ensure
    $stdout = old_stdout

  end

  return result
end
