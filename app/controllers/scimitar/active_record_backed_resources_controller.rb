require_dependency "scimitar/application_controller"

module Scimitar

  # An ActiveRecord-centric subclass of Scimitar::ResourcesController. See that
  # class's documentation first, as it describes things that your subclass must
  # do which apply equally to subclasses of this ActiveRecord-focused code.
  #
  # In addition to requirements mentioned above, your subclass MUST override
  # protected method #storage_scope, returning an ActiveRecord::Relation which
  # is used as a starting scope for any 'index' (list) views. This gives you an
  # opportunity to apply things like is-active filters, apply soft deletion
  # scopes, apply security scopes and so-on. For example:
  #
  #     protected
  #       def storage_scope
  #         self.storage_class().where(is_deleted: false)
  #       end
  #
  class ActiveRecordBackedResourcesController < ResourcesController

    rescue_from ActiveRecord::RecordNotFound, with: :handle_resource_not_found # See Scimitar::ApplicationController

    # GET (list)
    #
    def index
      query = if params[:filter].blank?
        self.storage_scope()
      else
        attribute_map = storage_class().new.scim_queryable_attributes()
        parser        = ::Scimitar::Lists::QueryParser.new(attribute_map)

        parser.parse(params[:filter])
        parser.to_activerecord_query(self.storage_scope())
      end

      pagination_info = scim_pagination_info(query.count())
      page_of_results = query
        .offset(pagination_info.offset)
        .limit(pagination_info.limit)
        .to_a()

      super(pagination_info, page_of_results) do | record |
        record.to_scim(location: url_for(action: :show, id: record.id))
      end
    end

    # GET/id (show)
    #
    def show
      super do |record_id|
        record = self.find_record(record_id)
        record.to_scim(location: url_for(action: :show, id: record_id))
      end
    end

    # POST (create)
    #
    def create
      super do |scim_resource|
        self.storage_class().transaction do
          record = self.storage_class().new
          record.from_scim!(scim_hash: scim_resource.as_json())
          self.save!(record)
          record.to_scim(location: url_for(action: :show, id: record.id))
        end
      end
    end

    # PUT (replace)
    #
    def replace
      super do |record_id, scim_resource|
        self.storage_class().transaction do
          record = self.find_record(record_id)
          record.from_scim!(scim_hash: scim_resource.as_json())
          self.save!(record)
          record.to_scim(location: url_for(action: :show, id: record.id))
        end
      end
    end

    # PATCH (update)
    #
    def update
      super do |record_id, patch_hash|
        self.storage_class().transaction do
          record = self.find_record(record_id)
          record.from_scim_patch!(patch_hash: patch_hash)
          self.save!(record)
          record.to_scim(location: url_for(action: :show, id: record.id))
        end
      end
    end

    # DELETE (remove)
    #
    def destroy
      super do |record_id|
        record = self.find_record(record_id)
        record.update_column(:is_active, false)
      end
    end

    # =========================================================================
    # PROTECTED INSTANCE METHODS
    # =========================================================================
    #
    protected

      # Return an ActiveRecord::Relation used as the starting scope for #index
      # lists and any 'find by ID' operation.
      #
      def storage_scope
        raise NotImplementedError
      end

      # Find a RIP user record. Subclasses can override this if they need
      # special lookup behaviour.
      #
      # +record_id+:: Record ID (SCIM schema 'id' value - "our" ID).
      #
      def find_record(record_id)
        self.storage_scope().find(record_id)
      end

      # Save a record, dealing with validation exceptions by raising SCIM
      # errors.
      #
      # +record+:: ActiveRecord subclass to save (via #save!).
      #
      # The return value is not used internally, making life easier for
      # overriding subclasses to "do the right thing" / avoid mistakes (instead
      # of e.g. requiring that a to-SCIM representation of 'record' is returned
      # and relying upon this to generate correct response payloads - an early
      # version of the gem did this and it caused a confusing subclass bug).
      #
      def save!(record)
        record.save!
      rescue ActiveRecord::RecordInvalid => exception
        raise Scimitar::ResourceInvalidError.new(record.errors.full_messages.join('; '))
      end

  end
end
