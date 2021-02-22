module Scimitar
  module Schema
    # Represnts the schema for the Name complex type
    # @see Scimitar::ComplexTypes::Name
    class Name < Base

      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'familyName', type: 'string'),
          Attribute.new(name: 'givenName', type: 'string'),
          Attribute.new(name: 'formatted', type: 'string', required: false)
        ]
      end

    end
  end
end
