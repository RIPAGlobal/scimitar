module Scim
  class MockUsersController < Scimitar::ResourcesController

    def index
      super(MockUser.all) do | mock_user |
        mock_user.to_scim(location: url_for(action: :show, id: mock_user.id))
      end
    end

    def show
      super do |mock_user_id|
        mock_user = find_user(mock_user_id)
        mock_user.to_scim(location: url_for(action: :show, id: mock_user_id))
      end
    end

    def create
      super(&method(:save))
    end

    def update
      super(&method(:save))
    end

    def destroy
      super do |mock_user_id|
        mock_user = find_user(mock_user_id)
        mock_user.destroy()
      end
    end

    # =========================================================================
    # PROTECTED INSTANCE METHODS
    # =========================================================================

    protected

      # Service method used by the base controller to determine *our* storage
      # model being handled by this SCIM subclass controller. The class must
      # mix in Scimitar::Resources::Mixin along with declaring various methods
      # described by the mixin. Our MockUser class does that.
      #
      def storage_class
        MockUser
      end

      # Find a MockUser record.
      #
      # +user_id+:: Mock user ID (SCIM schema 'id' value - "our" ID).
      #
      def find_user(mock_user_id)
        MockUser.find(mock_user_id)
      end

      # Map a SCIM User to a MockUser and save it. Normal parameters:
      #
      # +scim_user+:: The Scimitar::Resources::User to map and save.
      #
      # Optional named parameters:
      #
      # +is_create+:: Default +false+ for updates only; else +true+ to allow a
      #               new MockUser record to be created if the SCIM user does
      #               not correspond to an existing record.
      #
      def save(scim_user, is_create: false)
        puts "*"*80
        puts "SAVE #{scim_user.inspect}"
        puts "IS CREATE: #{is_create.inspect}"

        #convert the Scimitar::Resources::User to your application object
        #and save
      rescue ActiveRecord::RecordInvalid => exception
        # Map the enternal errors to a Scimitar error
        raise Scimitar::ResourceInvalidError.new()
      end

  end # "class UsersController < Scimitar::ResourcesController"
end # "module Scim"
