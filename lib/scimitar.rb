require 'scimitar/version'
require 'scimitar/engine'

module Scimitar
  def self.service_provider_configuration=(custom_configuration)
    @service_provider_configuration = custom_configuration
  end

  def self.service_provider_configuration(location:)
    @service_provider_configuration ||= ServiceProviderConfiguration.new
    @service_provider_configuration.meta.location = location
    @service_provider_configuration
  end
end
