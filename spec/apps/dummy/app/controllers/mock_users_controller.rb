class MockUsersController < Scimitar::ActiveRecordBackedResourcesController

  protected

    def storage_class
      MockUser
    end

    def storage_scope
      MockUser.all
    end

end
