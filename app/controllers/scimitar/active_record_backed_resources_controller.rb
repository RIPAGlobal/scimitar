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

    # GET (list)
    #
    def index
      super() do | record |
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
      super(&method(:save))
    end

    # PUT (replace) and PATCH (update)
    #
    def update
      super(&method(:save))
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
      rescue ActiveRecord::RecordNotFound
        handle_resource_not_found() # See Scimitar::ApplicationController
      end

      # Create, replace or update (patch) a RIP user from SCIM data.
      #
      # +scim_resource+:: The payload from the inbound write operation.
      # +operation+::     :create, :replace or :patch.
      #
      def save(scim_resource, operation)
        record = nil

        self.storage_class().transaction do
          case operation
            when :create
              record = self.storage_class().new
              record.from_scim!(scim_hash: scim_resource.as_json)

            when :replace
              record = self.find_record(scim_resource['id'])
              record.from_scim!(scim_hash: scim_resource.as_json)

            when :patch
              record = self.find_record(scim_resource['id'])
              record.from_scim_patch!(patch_hash: scim_resource.as_json)
          end

          record.save!
        end

      rescue ActiveRecord::RecordInvalid => exception
        raise Scimitar::ResourceInvalidError.new(record&.errors&.full_messages&.join('; ') || exception.message)

      end

  end
end
