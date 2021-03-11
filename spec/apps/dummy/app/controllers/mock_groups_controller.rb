module Scim
  class MockUsersController < Scimitar::ActiveRecordBackedResourcesController

    skip_before_action :verify_authenticity_token

    protected

      def storage_class
        MockGroup
      end

      def storage_scope
        MockGroup.all
      end

  end
end
