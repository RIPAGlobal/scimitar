require_dependency "scimitar/application_controller"

module Scimitar
  class SchemasController < ApplicationController
    def index
      schemas = Scimitar::Engine.schemas
      schemas_by_id = schemas.reduce({}) do |hash, schema|
        hash[schema.id] = schema
        hash
      end

      render json: schemas_by_id[params[:name]] || schemas
    end

  end
end
