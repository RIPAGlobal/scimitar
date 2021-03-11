module Scim
  class MockUsersController < Scimitar::ActiveRecordBackedResourcesController

    skip_before_action :verify_authenticity_token

    protected

      def storage_class
        MockUser
      end

      def storage_scope
        MockUser.all
      end

  end
end
