module Scimitar
  module Schema

    # Represents the schema for the Address complex type.
    #
    # See also Scimitar::ComplexTypes::Address
    #
    class Address < Base

      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'type',          type: 'string'),
          Attribute.new(name: 'formatted',     type: 'string'),
          Attribute.new(name: 'streetAddress', type: 'string'),
          Attribute.new(name: 'locality',      type: 'string'),
          Attribute.new(name: 'region',        type: 'string'),
          Attribute.new(name: 'postalCode',    type: 'string'),
          Attribute.new(name: 'country',       type: 'string'),
        ]
      end

    end
  end
end
