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
        @meta.location ||= Scimitar::Engine.routes.url_helpers.scim_schemas_path(name: id)
        original = super
        original.merge('attributes' => original.delete('scim_attributes'))
      end

      # Validates the resource against specific validations of each attribute,
      # for example if the type of the attribute matches the one defined in the
      # schema.
      #
      # +resource+:: A resource object that uses this schema.
      #
      def self.valid?(resource)
        cloned_scim_attributes.each do |scim_attribute|
          unless scim_attribute.valid?(resource.send(scim_attribute.name))
            resource.add_errors_from_hash(errors_hash: scim_attribute.errors.to_hash)
          end
        end
      end

      def self.cloned_scim_attributes
        scim_attributes.map { |scim_attribute| scim_attribute.clone }
      end

      # Find a given attribute this schema, travelling down a path to any
      # sub-attributes within. Given that callers might be dealing with paths
      # into actual SCIM data, array indices for multi-value attributes are
      # allowed (as integers) and simply skipped - only the names are of
      # interest.
      #
      # This is typically used to access attribute properties such as intended
      # mutability ('readOnly', 'readWrite', 'immutable', 'writeOnly').
      #
      # Returns the found Scimitar::Schema::Attribute or "nil".
      #
      # *path:: One or more attribute names as Strings, or Integer indices.
      #
      # For example, in a User schema, passing "name", "givenName" would find
      # the "givenName" attribute. Passing "emails", 0, "value" would find the
      # schema attribute for "value" under "emails", ignoring the array index
      # (since the schema is identical for each item in an array of values).
      #
      # See also Scimitar::Resources::Base::find_attribute
      #
      def self.find_attribute(*path)
        found_attribute    = nil
        current_attributes = self.scim_attributes()

        until path.empty? do
          current_path_entry = path.shift()
          next if current_path_entry.is_a?(Integer) # Skip array indicies arising from multi-value attributes

          current_path_entry = current_path_entry.to_s.downcase

          found_attribute = current_attributes.find do | attribute_to_check |
            attribute_to_check.name.to_s.downcase == current_path_entry
          end

          if found_attribute && path.present? # Any sub-attributes to check?...
            if found_attribute.subAttributes.present? # ...and are any defined?
              current_attributes = found_attribute.subAttributes
            else
              found_attribute = nil
              break # NOTE EARLY EXIT - tried to find a sub-attribute but there are none
            end
          else
            break # NOTE EARLY EXIT - no found attribute, or found target item at end of path
          end
        end # "until path.empty() do"

        return found_attribute
      end

    end
  end
end
