module Scimitar
  module Schema

    # Represents the schema for the ReferenceMember complex type,
    # referring to a member of a group (where members can themselves
    # be Users or Groups, identified by the "type" attribute). Used
    # by the Group SCIM resource's "members" array.
    #
    # See also Scimitar::ComplexTypes::ReferenceMember
    #
    class ReferenceMember < Scimitar::Resources::Base
      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'value',    type: 'string', mutability: 'immutable', required: true),
          Attribute.new(name: 'type',     type: 'string', mutability: 'immutable'),
          Attribute.new(name: 'display',  type: 'string', mutability: 'immutable'),
        ]
      end
    end
  end
end
