require_dependency "scimitar/application_controller"

module Scimitar
  class SchemasController < ApplicationController
    def index
      schemas = Scimitar::Engine.schemas

      schemas.each do |schema|
        schema.meta.location = scim_schemas_url(name: schema.id)
      end

      schemas_by_id = schemas.reduce({}) do |hash, schema|
        hash[schema.id] = schema
        hash
      end

      render json: schemas_by_id[params[:name]] || schemas
    end

  end
end
