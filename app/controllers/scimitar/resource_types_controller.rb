require_dependency "scimitar/application_controller"

module Scimitar
  class ResourceTypesController < ApplicationController
    def index
      resource_types = Scimitar::Engine.resources.map do |resource|
        resource.resource_type(scim_resource_type_url(name: resource.resource_type_id))
      end

      render json: resource_types
    end

    def show
      resource_types = Scimitar::Engine.resources.reduce({}) do |hash, resource|
        hash[resource.resource_type_id] = resource.resource_type(scim_resource_type_url(name: resource.resource_type_id))
        hash
      end

      render json: resource_types[params[:name]]
    end
  end
end
