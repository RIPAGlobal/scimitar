module Scimitar
  module Schema
    module DerivedAttributes
      extend ActiveSupport::Concern

      class_methods do
        def set_schema(schema)
          @schema = schema
          derive_attributes_from_schema(schema)
          schema
        end

        def derive_attributes_from_schema(schema)
          attr_accessor *schema.scim_attributes.map(&:name)
        end

        def schema
          @schema
        end
      end

    end
  end
end
