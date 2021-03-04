class MockUser < ActiveRecord::Base

  # ===========================================================================
  # TEST ATTRIBUTES - see db/migrate/20210304014602_create_mock_users.rb etc.
  # ===========================================================================

  READWRITE_ATTRS = %w{
    id
    scim_uid
    username
    first_name
    last_name
    work_email_address
    work_phone_number
  }

  # A fixed value read-only attribute, in essence.
  #
  def is_active
    true
  end

  # ===========================================================================
  # SCIM MIXIN AND REQUIRED METHODS
  # ===========================================================================

  def self.scim_resource_type
    return Scimitar::Resources::User
  end

  def self.scim_attributes_map
    return {
      id:         :id,
      externalId: :scim_uid,
      userName:   :username,
      name:       {
        givenName:  :first_name,
        familyName: :last_name
      },
      emails: [
        {
          match: 'type',
          with:  'work',
          using: {
            value:   :work_email_address,
            primary: true
          }
        },
      ],
      phoneNumbers: [
        {
          match: 'type',
          with:  'work',
          using: {
            value:   :work_phone_number,
            primary: false
          }
        },
      ],
      active: :is_active
    }
  end

  def self.scim_mutable_attributes
    return nil
  end

  def self.scim_queryable_attributes
    return {
      givenName:  :first_name,
      familyName: :last_name,
      emails:     :work_email_address,
    }
  end

  include Scimitar::Resources::Mixin
end
