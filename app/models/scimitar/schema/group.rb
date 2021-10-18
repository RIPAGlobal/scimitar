module Scimitar
  module Schema
    # Represents the schema for the Group resource
    # See also Scimitar::Resources::Group
    class Group < Scimitar::Resources::Base

      def initialize(options = {})
        super(name: 'Group',
              id: self.class.id,
              description: 'Represents a Group',
              scim_attributes: self.class.scim_attributes)
      end

      def self.id
        'urn:ietf:params:scim:schemas:core:2.0:Group'
      end

      def self.scim_attributes
        [
          Attribute.new(name: 'displayName', type: 'string', required: true),
          Attribute.new(name: 'members', multiValued: true, complexType: Scimitar::ComplexTypes::ReferenceMember, mutability: 'readWrite')
        ]
      end

    end
  end
end
