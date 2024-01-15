# For tests only - uses custom 'update' implementation which passes a block to
# Scimitar::ActiveRecordBackedResourcesController#create.
#
class CustomUpdateMockUsersController < Scimitar::ActiveRecordBackedResourcesController

  OVERRIDDEN_NAME = SecureRandom.uuid

  def update
    super do | resource |
      resource.first_name = OVERRIDDEN_NAME
      resource.save!
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
