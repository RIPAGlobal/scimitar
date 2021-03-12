class MockUsersController < Scimitar::ActiveRecordBackedResourcesController

  protected

    def storage_class
      MockGroup
    end

    def storage_scope
      MockGroup.all
    end

end
