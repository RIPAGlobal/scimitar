module Scimitar
  module Schema
    # Represnts the schema for the Email complex type
    # @see Scimitar::ComplexTypes::Email
    class Email < Base
      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'value', type: 'string'),
          Attribute.new(name: 'primary', type: 'boolean', required: false),
          Attribute.new(name: 'type', type: 'string', required: false)
        ]
      end
    end
  end
end
