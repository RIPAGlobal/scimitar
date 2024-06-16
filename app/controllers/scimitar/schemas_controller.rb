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

      list = if params.key?(:name)
        [ schemas_by_id[params[:name]] ]
      else
        schemas
      end

      render(json: {
        schemas: [
            'urn:ietf:params:scim:api:messages:2.0:ListResponse'
        ],
        totalResults: list.size,
        startIndex:   1,
        itemsPerPage: list.size,
        Resources:    list
      })
    end

  end
end
