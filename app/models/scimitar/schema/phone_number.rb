module Scimitar
  module Schema

    # Represents the schema for the PhoneNumber complex type.
    #
    # See also Scimitar::ComplexTypes::PhoneNumber
    #
    class PhoneNumber < Base
      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'value',   type: 'string'),
          Attribute.new(name: 'display', type: 'string', mutability: 'readOnly'),
          Attribute.new(name: 'type',    type: 'string'),
          Attribute.new(name: 'primary', type: 'boolean'),
        ]
      end
    end
  end
end
