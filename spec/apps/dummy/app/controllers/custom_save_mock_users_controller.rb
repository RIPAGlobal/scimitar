# For tests only - uses custom 'save!' implementation which passes a block to
# Scimitar::ActiveRecordBackedResourcesController#save!.
#
class CustomSaveMockUsersController < Scimitar::ActiveRecordBackedResourcesController

  CUSTOM_SAVE_BLOCK_USERNAME_INDICATOR = 'Custom save-block invoked'

  protected

    def save!(_record)
      super do | record |
        record.update!(username: CUSTOM_SAVE_BLOCK_USERNAME_INDICATOR)
      end
    end

    def storage_class
      MockUser
    end

    def storage_scope
      MockUser.all
    end

end
