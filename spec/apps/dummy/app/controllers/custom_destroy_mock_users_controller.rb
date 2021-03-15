# For tests only - uses custom 'destroy' implementation which passes a block to
# Scimitar::ActiveRecordBackedResourcesController#destroy.
#
class CustomDestroyMockUsersController < Scimitar::ActiveRecordBackedResourcesController

  NOT_REALLY_DELETED_USERNAME_INDICATOR = 'not really deleted'

  def destroy
    super do | resource |
      resource.update!(username: NOT_REALLY_DELETED_USERNAME_INDICATOR)
    end
  end

  protected

    def storage_class
      MockUser
    end

    def storage_scope
      MockUser.all
    end

end
