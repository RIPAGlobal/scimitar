require 'scimitar/version'
require 'scimitar/support/hash_with_indifferent_case_insensitive_access'
require 'scimitar/engine'

module Scimitar
  def self.service_provider_configuration=(custom_configuration)
    if @service_provider_configuration.nil? || ! custom_configuration.uses_defaults
      @service_provider_configuration = custom_configuration
    end
  end

  def self.service_provider_configuration(location:)
    @service_provider_configuration ||= ServiceProviderConfiguration.new
    @service_provider_configuration.meta.location = location
    @service_provider_configuration
  end

  def self.engine_configuration=(custom_configuration)
    if @engine_configuration.nil? || ! custom_configuration.uses_defaults
      @engine_configuration = custom_configuration
    end
  end

  def self.engine_configuration
    @engine_configuration ||= EngineConfiguration.new
    @engine_configuration
  end

  # Set in a "Rails.application.config.to_prepare" block by Scimitar itself to
  # establish default values. Older Scimitar client applications might not use
  # that wrapper; we don't want to overwrite settings they configured, but we
  # *do* want to let them overwrite the defaults. Thus, '||=" is used here but
  # not in ::service_provider_configuration=.
  #
  # Client applications should not call this method themselves.
  #
  def self.default_service_provider_configuration(default_configuration)
    @service_provider_configuration ||= custom_configuration
  end
end
