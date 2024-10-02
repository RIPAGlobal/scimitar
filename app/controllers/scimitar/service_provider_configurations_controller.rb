module Scimitar
  class ServiceProviderConfigurationsController < Scimitar::ApplicationController
    def show
      render json: Scimitar.service_provider_configuration(location: request.url)
    end
  end
end
