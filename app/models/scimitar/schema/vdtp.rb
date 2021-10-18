module Scimitar
  module Schema

    # Represents a common schema for a few complex types; base class DRYs up
    # code. "Vdtp" - Value, Display, Type, Primary.
    #
    class Vdtp < Scimitar::Resources::Base
      def self.scim_attributes
        @scim_attributes ||= [
          Attribute.new(name: 'value',   type: 'string', required: true),
          Attribute.new(name: 'display', type: 'string', mutability: 'readOnly'),
          Attribute.new(name: 'type',    type: 'string'),
          Attribute.new(name: 'primary', type: 'boolean'),
        ]
      end
    end
  end
end
