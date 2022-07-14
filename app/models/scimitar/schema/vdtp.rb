module Scimitar
  module Schema

    # Represents a common schema for a few complex types; base class DRYs up
    # code. "Vdtp" - Value, Display, Type, Primary.
    #
    class Vdtp < Base
      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'value',   type: 'string', required: Scimitar.engine_configuration.optional_value_fields_required),
          Attribute.new(name: 'display', type: 'string', mutability: 'readOnly'),
          Attribute.new(name: 'type',    type: 'string'),
          Attribute.new(name: 'primary', type: 'boolean'),
        ]
      end
    end
  end
end
