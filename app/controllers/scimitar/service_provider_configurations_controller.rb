module Scimitar
  class ServiceProviderConfigurationsController < ApplicationController
    def show
      render json: Scimitar.service_provider_configuration(location: request.url)
    end
  end
end
