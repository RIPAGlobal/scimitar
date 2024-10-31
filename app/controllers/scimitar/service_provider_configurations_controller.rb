module Scimitar
  class ServiceProviderConfigurationsController < ApplicationController
    def show
      service_provider_configuration = Scimitar.service_provider_configuration(location: request.url).as_json
      service_provider_configuration.delete("uses_defaults")
      render json: service_provider_configuration
    end
  end
end
