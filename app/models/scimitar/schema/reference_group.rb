module Scimitar
  module Schema

    # Represents the schema for the ReferenceGroup complex type,
    # referring to a group of which a user is a member - used in
    # a User SCIM resource's "groups" array.
    #
    # These are always read-only, with no ability to change the
    # membership list through a User. Change via Groups instead.
    #
    # See also Scimitar::ComplexTypes::ReferenceGroup
    #
    class ReferenceGroup < Base
      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'value',   type: 'string', mutability: 'readOnly', required: true),
          Attribute.new(name: 'display', type: 'string', mutability: 'readOnly'),
          Attribute.new(name: 'type',    type: 'string', mutability: 'readOnly'),
        ]
      end
    end
  end
end
