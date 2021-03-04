require_dependency "scimitar/application_controller"

module Scimitar
  class ResourcesController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :handle_resource_not_found

    def index(base_scope, &block)
      query = if params[:filter].present?
        parser = ::Scimitar::Lists::QueryParser.new(
          storage_class().new.scim_queryable_attributes(),
          params[:filter]
        )
        parser.to_activerecord_query(base_scope)
      else
        base_scope
      end

      counts = ::Scimitar::Lists::Count.new(
        start_index: params[:startIndex],
        limit:       params[:count],
        total:       query.count()
      )

      results = query.offset(counts.offset).limit(counts.limit).to_a

      render json: {
        schemas: [
            'urn:ietf:params:scim:api:messages:2.0:ListResponse'
        ],
        totalResults: counts.total,
        startIndex:   counts.start_index,
        itemsPerPage: counts.limit,
        Resources:    results.map(&block)
      }
    end

    def show(&block)
      scim_user = yield resource_params[:id]
      render json: scim_user
    rescue ErrorResponse => error
      handle_scim_error(error)
    end

    def create(&block)
      if resource_params[:id].present?
        handle_scim_error(ErrorResponse.new(status: 400, detail: 'id is not a valid parameter for create'))
        return
      end
      with_scim_resource() do |resource|
        render json: yield(resource, is_create: true), status: :created
      end
    end

    def update(&block)
      with_scim_resource() do |resource|
        render json: yield(resource)
      end
    end

    def destroy
      if yield(resource_params[:id]) != false
        head :no_content
      else
        five_hundred = ErrorResponse.new(
          status: 500,
          detail: "Failed to delete the resource with id '#{params[:id]}'. Please try again later."
        )
        handle_scim_error(five_hundred)
      end
    end

    protected

      # The class including Scimitar::Resources::Mixin which declares mappings
      # to the entity you return in #resource_type.
      #
      def storage_class
        raise NotImplementedError
      end

    private

      def validate_request
        if request.raw_post.blank?
          raise Scimitar::ErrorResponse.new(status: 400, detail: 'must provide a request body')
        end
      end

      def with_scim_resource
        validate_request()

        resource_type = storage_class().scim_resource_type() # See Scimitar::Resources::Mixin

        begin
          resource = resource_type.new(resource_params.to_h)
          unless resource.valid?
            raise Scimitar::ErrorResponse.new(
              status:   400,
              detail:   "Invalid resource: #{resource.errors.full_messages.join(', ')}.",
              scimType: 'invalidValue'
            )
          end

          yield(resource)
        rescue NoMethodError => error
          Rails.logger.error(error)
          raise Scimitar::ErrorResponse.new(status: 400, detail: 'invalid request')
        end
      rescue Scimitar::ErrorResponse => error
        handle_scim_error(error)
      end

      def resource_params
        params.permit!
      end

  end
end
