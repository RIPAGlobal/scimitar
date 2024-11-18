require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)

require 'scimitar'

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.0

    # Silence the following under Rails 8.0:
    #
    # "DEPRECATION WARNING: `to_time` will always preserve the full timezone
    # rather than offset of the receiver in Rails 8.1. To opt in to the new
    # behavior, set `config.active_support.to_time_preserves_timezone = :zone`"
    #
    config.active_support.to_time_preserves_timezone = :zone
  end
end

