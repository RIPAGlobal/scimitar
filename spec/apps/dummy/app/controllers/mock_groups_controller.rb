module Scim
  class MockGroupsController < Scimitar::ResourcesController

    skip_before_action :verify_authenticity_token

    def index
      super(MockGroup.all) do | mock_group |
        mock_group.to_scim(location: url_for(action: :show, id: mock_group.id))
      end
    end

    def show
      super do |mock_group_id|
        mock_group = find_group(mock_group_id)
        mock_group.to_scim(location: url_for(action: :show, id: mock_group_id))
      end
    end

    def create
      super(&method(:save))
    end

    def update
      super(&method(:save))
    end

    def destroy
      super do |mock_group_id|
        mock_group = find_group(mock_group_id)
        mock_group.destroy()
      end
    end

    # =========================================================================
    # PROTECTED INSTANCE METHODS
    # =========================================================================

    protected

      # Service method used by the base controller to determine *our* storage
      # model being handled by this SCIM subclass controller. The class must
      # mix in Scimitar::Resources::Mixin along with declaring various methods
      # described by the mixin. Our MockGroup class does that.
      #
      def storage_class
        MockGroup
      end

      # Find a MockGroup record.
      #
      # +group_id+:: Mock group ID (SCIM schema 'id' value - "our" ID).
      #
      def find_group(mock_group_id)
        MockGroup.find(mock_group_id)
      end

      # Map a SCIM Group to a MockGroup and save it. Normal parameters:
      #
      # +scim_group+:: The Scimitar::Resources::Group to map and save.
      #
      # Optional named parameters:
      #
      # +is_create+:: Default +false+ for updates only; else +true+ to allow a
      #               new MockGroup record to be created if the SCIM group does
      #               not correspond to an existing record.
      #
      def save(scim_group, is_create: false)
        instance = if is_create
          MockGroup.new
        else
          find_group(scim_group['id'])
        end

        instance.from_scim!(scim_object: scim_group)
        instance.save!

      rescue ActiveRecord::RecordInvalid => exception
        # Map the enternal errors to a Scimitar error
        raise Scimitar::ResourceInvalidError.new(instance.errors.full_messages.join('; '))
      end

  end # "class GroupsController < Scimitar::ResourcesController"
end # "module Scim"
