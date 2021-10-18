module Scimitar
  module Schema

    # Represents the schema for the X509Certificate complex type.
    # The 'value' holds the certificate data.
    #
    # Similar to the Vdtp class, but the "value" field is of type "binary".
    #
    # See also Scimitar::ComplexTypes::X509Certificate
    #
    class X509Certificate < Scimitar::Resources::Base
      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'value',   type: 'binary', required: true),
          Attribute.new(name: 'display', type: 'string', mutability: 'readOnly'),
          Attribute.new(name: 'type',    type: 'string'),
          Attribute.new(name: 'primary', type: 'boolean'),
        ]
      end
    end
  end
end
