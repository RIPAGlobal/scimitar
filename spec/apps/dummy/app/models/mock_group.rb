class MockGroup < ActiveRecord::Base

  # ===========================================================================
  # TEST ATTRIBUTES - see db/migrate/20210308020313_create_mock_groups.rb etc.
  # ===========================================================================

  READWRITE_ATTRS = %w{
    id
    scim_uid
    display_name
    scim_users_and_groups
  }

  has_and_belongs_to_many :mock_users

  has_many :child_mock_groups, class_name: 'MockGroup', foreign_key: 'parent_id'

  # ===========================================================================
  # SCIM ADAPTER ACCESSORS
  #
  # Groups in SCIM can contain users or other groups. That's why the :find_with
  # key in the Hash returned by ::scim_attributes_map has to check the type of
  # thing it needs to find. Since the mappings only support a single read/write
  # accessor, we need custom accessors to do what SCIM is expecting by turning
  # the Rails associations to/from mixed, flat arrays of mock users and groups.
  # ===========================================================================

  def scim_users_and_groups
    self.mock_users.to_a + self.child_mock_groups.to_a
  end

  def scim_users_and_groups=(mixed_array)
    self.mock_users        = mixed_array.select { |item| item.is_a?(MockUser)  }
    self.child_mock_groups = mixed_array.select { |item| item.is_a?(MockGroup) }
  end

  # ===========================================================================
  # SCIM MIXIN AND REQUIRED METHODS
  # ===========================================================================

  def self.scim_resource_type
    return Scimitar::Resources::Group
  end

  def self.scim_attributes_map
    return {
      id:          :id,
      externalId:  :scim_uid,
      displayName: :display_name,
      members:     [ # NB read-write, though individual items' attributes are immutable
        list:  :scim_users_and_groups, # See adapter accessors, earlier in this file
        using: {
          value: :id
        },
        find_with: -> (scim_list_entry) {
          id   = scim_list_entry['value']
          type = scim_list_entry['type' ] || 'User' # Some online examples omit 'type' and believe 'User' will be assumed

          case type.downcase
            when 'user'
              MockUser.find_by_id(id)
            when 'group'
              MockGroup.find_by_id(id)
            else
              raise Scimitar::InvalidSyntaxError.new("Unrecognised type #{type.inspect}")
          end
        }
      ]
    }
  end

  def self.scim_mutable_attributes
    return nil
  end

  def self.scim_queryable_attributes
    return {
      displayName: :display_name
    }
  end

  include Scimitar::Resources::Mixin
end
