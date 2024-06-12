module Scimitar
  module Schema
    # Represents the schema for the Name complex type
    # See also Scimitar::ComplexTypes::Name
    class Name < Base

      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'familyName',       type: 'string'),
          Attribute.new(name: 'givenName',        type: 'string'),
          Attribute.new(name: 'middleName',       type: 'string'),
          Attribute.new(name: 'formatted',        type: 'string'),
          Attribute.new(name: 'honorificPrefix',  type: 'string'),
          Attribute.new(name: 'honorificSuffix',  type: 'string'),
        ]
      end

    end
  end
end
