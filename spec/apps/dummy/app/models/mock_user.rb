class MockUser
  include ActiveModel::Model

  # ===========================================================================
  # MOCK ATTRIBUTES
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

  attr_accessor(*READWRITE_ATTRS)

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
          value: :work_email_address
        }
      ],
      phoneNumbers: [
        {
          value: :work_phone_number
        }
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
