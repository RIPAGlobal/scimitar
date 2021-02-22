module Scimitar
  module Schema
    # Represnts the schema for the Reference complex type
    # @see Scimitar::ComplexTypes::Reference
    class Reference < Base
      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'value', type: 'string', mutability: 'readOnly'),
          Attribute.new(name: 'display', type: 'string', mutability: 'readOnly', required: false)
        ]
      end
    end
  end
end
