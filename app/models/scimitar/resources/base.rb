module Scimitar
  module Resources
    # The base class for all SCIM resources.
    class Base
      include ActiveModel::Model
      include Scimitar::Schema::DerivedAttributes
      include Scimitar::Errors

      attr_accessor :id, :externalId, :meta
      attr_reader :errors
      validate :validate_resource

      def initialize(options = {})
        flattended_attributes = flatten_extension_attributes(options)
        attributes = flattended_attributes.with_indifferent_access.slice(*self.class.all_attributes)
        super(attributes)
        constantize_complex_types(attributes)
        @errors = ActiveModel::Errors.new(self)
      end

      def flatten_extension_attributes(options)
        flattened = options.dup
        self.class.extended_schemas.each do |extended_schema|
          if extension_attrs = flattened.delete(extended_schema.id)
            flattened.merge!(extension_attrs)
          end
        end
        flattened
      end

      # Can be used to extend an existing resource type's schema. For example:
      #
      #     module Scim
      #       module Schema
      #         class MyExtension < Scimitar::Schema::Base
      #
      #           def initialize(options = {})
      #             super(name: 'ExtendedGroup',
      #                   id: self.class.id,
      #                   description: 'Represents extra info about a group',
      #                   scim_attributes: self.class.scim_attributes)
      #           end
      #
      #           def self.id
      #             'urn:ietf:params:scim:schemas:extension:extendedgroup:2.0:Group'
      #           end
      #
      #           def self.scim_attributes
      #             [Scimitar::Schema::Attribute.new(name: 'someAddedAttribute',
      #                            type: 'string',
      #                            required: true,
      #                            canonicalValues: ['FOO', 'BAR'])]
      #           end
      #         end
      #       end
      #     end
      #
      #     Scimitar::Resources::Group.extend_schema Scim::Schema::MyExtension
      #
      def self.extend_schema(schema)
        derive_attributes_from_schema(schema)
        extended_schemas << schema
      end

      def self.extended_schemas
        @extended_schemas ||= []
      end

      def self.schemas
        ([schema] + extended_schemas).flatten
      end

      def self.all_attributes
        scim_attributes = schemas.map(&:scim_attributes).flatten.map(&:name)
        scim_attributes + [:id, :externalId, :meta]
      end

      # Calls to Scimitar::Schema::Base::find_attribute for each of the schemas
      # in ::schemas, in order returned (so main schema would be first, then
      # any extended schemas searched next). Returns the first match found, or
      # +nil+.
      #
      # See Scimitar::Schema::Base::find_attribute for details on parameters,
      # more about the return value and other general information.
      #
      def self.find_attribute(*path)
        found_attribute = nil

        self.schemas.each do | schema |
          found_attribute = schema.find_attribute(*path)
          break unless found_attribute.nil?
        end

        return found_attribute
      end

      def self.complex_scim_attributes
        schema.scim_attributes.select(&:complexType).group_by(&:name)
      end

      def complex_type_from_hash(scim_attribute, attr_value)
        if attr_value.is_a?(Hash)
          scim_attribute.complexType.new(attr_value)
        else
          attr_value
        end
      end

      def constantize_complex_types(hash)
        hash.with_indifferent_access.each_pair do |attr_name, attr_value|
          scim_attribute = self.class.complex_scim_attributes[attr_name].try(:first)
          if scim_attribute && scim_attribute.complexType
            if scim_attribute.multiValued
              self.send("#{attr_name}=", attr_value.map {|attr_for_each_item| complex_type_from_hash(scim_attribute, attr_for_each_item)})
            else
              self.send("#{attr_name}=", complex_type_from_hash(scim_attribute, attr_value))
            end
          end
        end
      end

      def as_json(options = {})
        self.meta = Meta.new unless self.meta
        meta.resourceType = self.class.resource_type_id
        original_hash = super(options).except('errors')
        original_hash.merge!('schemas' => self.class.schemas.map(&:id))
        self.class.extended_schemas.each do |extension_schema|
          extension_attributes = extension_schema.scim_attributes.map(&:name)
          original_hash.merge!(extension_schema.id => original_hash.extract!(*extension_attributes))
        end
        original_hash
      end

      def self.resource_type_id
        name.demodulize
      end

      def self.resource_type(location)
        resource_type = ResourceType.new(
          endpoint: endpoint,
          schema: schema.id,
          id: resource_type_id,
          name: resource_type_id,
          schemaExtensions: extended_schemas.map(&:id)
        )

        resource_type.meta.location = location
        resource_type
      end

      def validate_resource
        self.class.schema.valid?(self)
        self.class.extended_schemas.each do |extended_schema|
          extended_schema.valid?(self)
        end
      end
    end
  end
end
