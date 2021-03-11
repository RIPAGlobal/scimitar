require_dependency "scimitar/application_controller"

module Scimitar

  # A Rails controller which is largely idiomatic, with #index, #show, #create
  # and #destroy methods mapping to the conventional HTTP methods in Rails as
  # well as #update, which can be called for either PUT or PATCH.
  #
  # Subclass this controller to deal with resource-specific API calls, for
  # endpoints such as Users and Groups. Any one controller is assumed to be
  # related to one class in your application which has mixed in
  # Scimitar::Resources::Mixin. Your subclass MUST override protected method
  # #storage_class, which returns that class. For example, if you had a class
  # User with the mixin included, then:
  #
  #     protected
  #       def storage_class
  #         User
  #       end
  #
  # ...is sufficient.
  #
  # The controller makes no assumptions about storage method - it does not have
  # any ActiveRecord specialisations, for example. If you do use ActiveRecord,
  # consider subclassing Scimitar::ActiveRecordBackedResourcesController
  # instead as it does most of the mapping, persistence and error handling work
  # for you.
  #
  class ResourcesController < ApplicationController

    # GET (list)
    #
    def index(base_scope, &block)
      query = if params[:filter].present?
        attribute_map = storage_class().new.scim_queryable_attributes()
        parser        = ::Scimitar::Lists::QueryParser.new(attribute_map)

        parser.parse(params[:filter])
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

    # GET/id (show)
    #
    def show(&block)
      scim_resource = yield(self.resource_params()[:id])
      render json: scim_resource
    rescue ErrorResponse => error
      handle_scim_error(error)
    end

    # POST (create)
    #
    def create(&block)
      if self.resource_params()[:id].present?
        handle_scim_error(ErrorResponse.new(status: 400, detail: 'id is not a valid parameter for create'))
        return
      end

      with_scim_resource() do |resource|
        render json: yield(resource, :create), status: :created
      end
    end

    # PUT (replace) and PATCH (update)
    #
    def update(&block)
      with_scim_resource() do |resource|
        render json: yield(resource, request.patch? ? :patch : :replace)
      end
    end

    # DELETE (remove)
    #
    def destroy
      if yield(self.resource_params()[:id]) != false
        head :no_content
      else
        five_hundred = ErrorResponse.new(
          status: 500,
          detail: "Failed to delete the resource with id '#{params[:id]}'. Please try again later."
        )
        handle_scim_error(five_hundred)
      end
    end

    # =========================================================================
    # PROTECTED INSTANCE METHODS
    # =========================================================================
    #
    protected

      # The class including Scimitar::Resources::Mixin which declares mappings
      # to the entity you return in #resource_type.
      #
      def storage_class
        raise NotImplementedError
      end

    # =========================================================================
    # PRIVATE INSTANCE METHODS
    # =========================================================================
    #
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
          resource = resource_type.new(self.resource_params().to_h)

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
