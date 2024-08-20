module Scimitar

  # A Rails controller which is mostly idiomatic, with #index, #show, #create
  # and #destroy methods mapping to the conventional HTTP methods in Rails.
  # The #update method is used for partial-update PATCH calls, while the
  # #replace method is used for whole-update PUT calls.
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
    # Pass a Scimitar::Lists::Count object providing pagination data along with
    # a page of results in "your" data domain as an Enumerable, along with a
    # block. Renders as "list" result by calling your block with each of the
    # results, allowing you to use something like
    # Scimitar::Resources::Mixin#to_scim to convert to a SCIM representation.
    #
    # +pagination_info+:: A Scimitar::Lists::Count instance with #total set.
    #                     See e.g. protected method #scim_pagination_info to
    #                     assist with this.
    #
    # +page_of_results+:: An Enumerable single page of results.
    #
    def index(pagination_info, page_of_results, &block)
      render(json: {
        schemas: [
            'urn:ietf:params:scim:api:messages:2.0:ListResponse'
        ],
        totalResults: pagination_info.total,
        startIndex:   pagination_info.start_index,
        itemsPerPage: pagination_info.limit,
        Resources:    page_of_results.map(&block)
      })
    end

    # GET/id (show)
    #
    # Call with a block that is passed an ID to find in "your" domain. Evaluate
    # to the SCIM representation of the arising found record.
    #
    def show(&block)
      scim_resource = yield(self.safe_params[:id])
      render(json: scim_resource)
    end

    # POST (create)
    #
    # Call with a block that is passed a SCIM resource instance - e.g a
    # Scimitar::Resources::User instance - representing an item to be created.
    # Your ::storage_class class's ::scim_resource_type method determines the
    # kind of object you'll be given.
    #
    # See also e.g. Scimitar::Resources::Mixin#from_scim!.
    #
    # Evaluate to the SCIM representation of the arising created record.
    #
    def create(&block)
      with_scim_resource do |resource|
        render(json: yield(resource, :create), status: :created)
      end
    end

    # PUT (replace)
    #
    # Similar to #create, but you're passed an ID to find as well as the
    # resource details to then use for all replacement attributes in that found
    # resource. See also e.g. Scimitar::Resources::Mixin#from_scim!.
    #
    # Evaluate to the SCIM representation of the arising created record.
    #
    def replace(&block)
      with_scim_resource do |resource|
        render(json: yield(self.safe_params[:id], resource))
      end
    end

    # PATCH (update)
    #
    # A variant of #create where you're again passed the resource ID (in "your"
    # domain) to look up, but then a Hash with patch operation details from the
    # calling client. This can be passed to e.g.
    # Scimitar::Resources::Mixin#from_scim_patch!.
    #
    # Evaluate to the SCIM representation of the arising created record.
    #
    def update(&block)
      validate_request

      # Params includes all of the PATCH data at the top level along with other
      # other Rails-injected params like 'id', 'action', 'controller'. These
      # are harmless given no namespace collision and we're only interested in
      # the 'Operations' key for the actual patch data.
      #
      render(json: yield(self.safe_params[:id], self.safe_params.to_hash))
    end

    # DELETE (remove)
    #
    def destroy
      if yield(self.safe_params[:id]) != false
        head :no_content
      else
        raise ErrorResponse.new(
          status: 500,
          detail: "Failed to delete the resource with id '#{params[:id]}'. Please try again later."
        )
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

      # For #index actions, returns a Scimitar::Lists::Count instance which can
      # be used to access offset-vs-start-index (0-indexed or 1-indexed),
      # per-page limit and also holds the total number-of-items count which you
      # can optionally pass up-front here, or set via #total= later.
      #
      # +total_count+:: Optional integer total record count across all pages,
      #                 else must be set later - BEFORE passing an instance to
      #                 the #index implementation in this class.
      #
      def scim_pagination_info(total_count = nil)
        ::Scimitar::Lists::Count.new(
          start_index: params[:startIndex],
          limit:       params[:count] || Scimitar.service_provider_configuration(location: nil).filter.maxResults,
          total:       total_count
        )
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
        validate_request

        resource_type = storage_class.scim_resource_type # See Scimitar::Resources::Mixin
        resource      = resource_type.new(self.safe_params.to_h)

        if resource.valid?
          yield(resource)
        else
          raise Scimitar::ErrorResponse.new(
            status:   400,
            detail:   "Invalid resource: #{resource.errors.full_messages.join(', ')}.",
            scimType: 'invalidValue'
          )
        end

      # Gem bugs aside - if this happens, we couldn't create "resource"; bad
      # (or unsupported) attributes encountered in inbound payload data.
      #
      rescue NoMethodError => exception
        Rails.logger.error("#{exception.message}\n#{exception.backtrace}")
        raise Scimitar::ErrorResponse.new(status: 400, detail: 'Invalid request')
      end

      def safe_params
        params.permit!
      end

  end
end
