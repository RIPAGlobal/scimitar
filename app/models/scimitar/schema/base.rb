module Scimitar
  module Schema
    # The base class that each schema class must inherit from.
    # These classes represent the schema of a SCIM resource or a complex type that could be used in a resource.
    class Base
      include ActiveModel::Model
      attr_accessor :id, :name, :description, :scim_attributes, :meta

      def initialize(options = {})
        super
        @meta = Meta.new(resourceType: 'Schema')
      end

      # Converts the schema to its json representation that will be returned by /SCHEMAS end-point of a SCIM service provider.
      def as_json(options = {})
        @meta.location = Scimitar::Engine.routes.url_helpers.scim_schemas_path(name: id)
        original = super
        original.merge('attributes' => original.delete('scim_attributes'))
      end

      # Validates the resource against specific validations of each attribute,for example if the type of the attribute matches the one defined in the schema.
      # @param resource [Object] a resource object that uses this schema
      def self.valid?(resource)
        cloned_scim_attributes.each do |scim_attribute|
          resource.add_errors_from_hash(scim_attribute.errors.to_hash) unless scim_attribute.valid?(resource.send(scim_attribute.name))
        end
      end

      def self.cloned_scim_attributes
        scim_attributes.map { |scim_attribute| scim_attribute.clone }
      end

    end
  end
end
