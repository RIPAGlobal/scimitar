require_dependency "scimitar/application_controller"

module Scimitar
  class ResourcesController < ApplicationController

    def index(&block)

      # Do all the count and filter stuff...

      results = yield resource_params

      render json: {
        "schemas": [
            "urn:ietf:params:scim:api:messages:2.0:ListResponse"
        ],
        "totalResults": results.total,
        "startIndex":   results.start_index,
        "itemsPerPage": results.limit,
        "Resources":    results.objects.map do | scim_user |
          user.to_scim(location: url_for(action: :show, id: user_id))
        end
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
      with_scim_resource(resource_type()) do |resource|
        render json: yield(resource, is_create: true), status: :created
      end
    end

    def update(&block)
      with_scim_resource(resource_type()) do |resource|
        render json: yield(resource)
      end
    end

    def destroy
      if yield(resource_params[:id]) != false
        head :no_content
      else
        handle_scim_error(ErrorResponse.new(status: 500, detail: "Failed to delete the resource with id '#{params[:id]}'. Please try again later"))
      end
    end

    protected

      # Declare which SCIM resource you're handling. This is currently only
      # used to DRY up code in this example, but the base controller migth
      #
      def resource_type
        raise NotImplementedError
      end

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

      def with_scim_resource(resource_type())
        validate_request
        begin
          resource = resource_type().new(resource_params.to_h)
          unless resource.valid?
            raise Scimitar::ErrorResponse.new(status: 400,
                                                detail: "Invalid resource: #{resource.errors.full_messages.join(', ')}.",
                                                scimType: 'invalidValue')
          end

          yield(resource)
        rescue NoMethodError => error
          Rails.logger.error error
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
