require_dependency "scimitar/application_controller"

module Scimitar
  class SchemasController < ApplicationController
    def index
      schemas = Scimitar::Engine.schemas

      schemas.each do |schema|
        schema.meta.location = scim_schemas_url(name: schema.id)
      end

      schemas_by_id = schemas.reduce({}) do |hash, schema|
        hash[schema.id] = schema
        hash
      end

      list = if params.key?(:name)
        [ schemas_by_id[params[:name]] ]
      else
        schemas
      end

      # Figure out which classes (of those currently loaded - autoloaders take
      # note!) use the Scimitar resource mixin. The resource classes tell us
      # which SCIM resource class they represent and that, in turn, tells us
      # which schema(s) are involved; the resource classes also contain the
      # SCIM schema to local class attribute map.
      #
      classes_using_scimitar_mixin = Module.constants.filter_map do |c|
        value = Module.const_get(c) rescue nil

        value if (
          value.is_a?(Class) &&
          value.include?(Scimitar::Resources::Mixin) &&
          value.respond_to?(:scim_resource_type) &&
          value.respond_to?(:scim_attributes_map)
        )
      end

      # Take the schema list and map it to rewritten versions based on finding
      # out which of the above resource classes use a given schema and then
      # walking this schema's attribute tree while comparing notes against the
      # resource class's attribute map. Unmapped attributes are removed and the
      # reality of resource class attribute mutability might cause a different
      # answer for the corresponding schema attribute's mutability; for any
      # custom schema we'd expect a match, but for core schema where the local
      # resources don't quite work to spec, at least the /Schemas endpoint can
      # try to reflect reality and aid auto-discovery.
      #
      list.map! do | schema_instance |
        found_class = classes_using_scimitar_mixin.find do | class_using_scimitar_mixin |
          resource_class = class_using_scimitar_mixin.scim_resource_type()

          resource_class.schema == schema_instance.class ||
          resource_class.extended_schemas.include?(schema_instance.class)
        end

        rebuilt_schema_instance = if found_class
          rebuild_schema_through_mappings(
            original_schema_instance:   schema_instance,
            class_using_scimitar_mixin: found_class
          )
        else
          nil
        end

        rebuilt_schema_instance
      end

      list.compact!

      render(json: {
        schemas: [
            'urn:ietf:params:scim:api:messages:2.0:ListResponse'
        ],
        totalResults: list.size,
        startIndex:   1,
        itemsPerPage: list.size,
        Resources:    list
      })
    end

    # =========================================================================
    # PRIVATE INSTANCE METHODS
    # =========================================================================
    #
    private


      # NB note in docs that it's not necessarily *all* dup'd so don't assume
      # it (case of associated lists where class inside list cannot be determined)


      def rebuild_schema_through_mappings(
        original_schema_instance:,
        class_using_scimitar_mixin:,

        scim_attributes_map:     nil,
        schema_attributes:       nil,
        rebuilt_attribute_array: nil
      )
        schema_attributes   ||= original_schema_instance.scim_attributes
        scim_attributes_map ||= class_using_scimitar_mixin
          .scim_attributes_map()
          .with_indifferent_case_insensitive_access()

        rebuilt_schema_instance = nil

        if rebuilt_attribute_array.nil?
          rebuilt_schema_instance                 = original_schema_instance.dup()
          rebuilt_schema_instance.scim_attributes = []
          rebuilt_attribute_array                 = rebuilt_schema_instance.scim_attributes
        end

        schema_attributes.each do | schema_attribute |
          if schema_attribute.multiValued && schema_attribute.subAttributes&.any?
            mapped_multivalue_attribute = scim_attributes_map[schema_attribute.name]

            # We expect either an array in the attribute map to correspond with
            # a multivalued schema attribute, or nothing. If we get some other
            # non-Array, not-nil thing, it's just ignored.
            #
            if mapped_multivalue_attribute.is_a?(Array)

              # A single-entry array with "list using" semantics, for a
              # collection of an artbirary number of same-class items - e.g.
              # Groups to which a User belongs.
              #
              # If this is an up-to-date mapping, there's a "class" entry that
              # tells us what the collection is compromised of. If not, then we
              # check for ActiveRecord collections as a fallback and if that is
              # the case here, can use reflection to try and find the class. If
              # all else fails, we drop to generic schema for the collection.
              #
              if mapped_multivalue_attribute.first&.dig(:list)
                associated_resource_class = mapped_multivalue_attribute.first[:class]

                if (
                  associated_resource_class.nil? &&
                  class_using_scimitar_mixin < ActiveRecord::Base
                )
                  associated_resource_class = class_using_scimitar_mixin
                    .reflect_on_association(mapped_multivalue_attribute.first[:list])
                    &.klass
                end

                if associated_resource_class.nil? || ! associated_resource_class.include?(Scimitar::Resources::Mixin)
                  rebuilt_attribute_array << schema_attribute
                else
                  rebuilt_schema_attribute = schema_attribute.dup()
                  rebuilt_schema_attribute.subAttributes = []
                  rebuilt_attribute_array << rebuilt_schema_attribute

                  rebuild_schema_through_mappings(
                    original_schema_instance:   original_schema_instance,
                    class_using_scimitar_mixin: associated_resource_class,
                    scim_attributes_map:        mapped_multivalue_attribute.first[:using],
                    schema_attributes:          schema_attribute.subAttributes,
                    rebuilt_attribute_array:    rebuilt_schema_attribute.subAttributes
                  )
                end

              # A one-or-more entry array with "match with" semantics, to match
              # discrete mapped items with a particular value in a particular
              # field - e.g. an e-mail of type "work" mapping the SCIM "value"
              # to a local attribute of "work_email_address".
              #
              # Mutability or supported attributes here might vary per matched
              # type. There's no way for SCIM schema to represent that so we
              # just merge all the "using" mappings together, in order of array
              # appearance, and have that combined attribute map treated as the
              # data the schema response will use.
              #
              elsif mapped_multivalue_attribute.first&.dig(:match)
                union_of_mappings = {}

                mapped_multivalue_attribute.each do | mapped_multivalue_attribute_description |
                  union_of_mappings.merge!(mapped_multivalue_attribute_description[:using])
                end

                rebuilt_schema_attribute = schema_attribute.dup()
                rebuilt_schema_attribute.subAttributes = []
                rebuilt_attribute_array << rebuilt_schema_attribute

                rebuild_schema_through_mappings(
                  original_schema_instance:   original_schema_instance,
                  class_using_scimitar_mixin: class_using_scimitar_mixin,
                  scim_attributes_map:        union_of_mappings,
                  schema_attributes:          schema_attribute.subAttributes,
                  rebuilt_attribute_array:    rebuilt_schema_attribute.subAttributes
                )
              end
            end

          elsif schema_attribute.subAttributes&.any?
            mapped_subattributes = scim_attributes_map[schema_attribute.name]

            if mapped_subattributes.is_a?(Hash)
              rebuilt_schema_attribute = schema_attribute.dup()
              rebuilt_schema_attribute.subAttributes = []
              rebuilt_attribute_array << rebuilt_schema_attribute

              rebuild_schema_through_mappings(
                original_schema_instance:   original_schema_instance,
                class_using_scimitar_mixin: class_using_scimitar_mixin,
                scim_attributes_map:        mapped_subattributes,
                schema_attributes:          schema_attribute.subAttributes,
                rebuilt_attribute_array:    rebuilt_schema_attribute.subAttributes
              )
            end

          else
            mapped_attribute = scim_attributes_map[schema_attribute.name]

            unless mapped_attribute.nil?
              rebuilt_schema_attribute = schema_attribute.dup()
              has_mapped_reader        = true
              has_mapped_writer        = false

              if mapped_attribute.is_a?(String) || mapped_attribute.is_a?(Symbol)
                has_mapped_reader = class_using_scimitar_mixin.new.respond_to?(mapped_attribute)
                has_mapped_writer = class_using_scimitar_mixin.new.respond_to?("#{mapped_attribute}=")
              end

              # The schema is taken as the primary source of truth, leading to
              # a matrix of "do we override it or not?" based on who is the
              # more limited. When both have the same mutability there is no
              # more work to do, so we just need to consider differences:
              #
              # Actual class support   Schema says   Result
              # =============================================================
              # readWrite              readOnly      readOnly  (schema wins)
              # readWrite              writeOnly     writeOnly (schema wins)
              # readOnly               readWrite     readOnly  (class wins)
              # writeOnly              readWrite     writeOnly (class wins)
              #
              # Those cases are easy. But there are gnarly cases too, where we
              # have no good answer and the class's mapped implementation is in
              # essence broken compared to the schema. Since it is not useful
              # to insist on the schema's not-reality version, the class wins.
              #
              # Actual class support   Schema says   Result
              # ====================== =======================================
              # readOnly               writeOnly     readOnly  (class "wins")
              # writeOnly              readOnly      writeOnly (class "wins")

              schema_attribute_mutability = schema_attribute.mutability.downcase

              if has_mapped_reader && has_mapped_writer
                #
                # Read-write Nothing to do. Schema always "wins" by matching or
                # being more restrictive than the class's actual abilities.

              elsif has_mapped_reader && ! has_mapped_writer
                #
                # Read-only. Class is more restrictive if schema is 'readWrite'
                # or if there's the broken clash of schema 'writeOnly'.
                #
                if schema_attribute_mutability == 'readwrite' || schema_attribute_mutability == 'writeonly'
                  rebuilt_schema_attribute.mutability = 'readOnly'
                end

              elsif has_mapped_writer && ! has_mapped_reader
                #
                # Opposite to the above case.
                #
                if schema_attribute_mutability == 'readwrite' || schema_attribute_mutability == 'readonly'
                  rebuilt_schema_attribute.mutability = 'writeOnly'
                end

                # ...else we cannot fathom how this class works - it appears to
                # have no read or write accessor for the mapped attribute. Keep
                # the schema's declaration as-is.
                #
              end

              rebuilt_attribute_array << rebuilt_schema_attribute
            end
          end
        end

        return rebuilt_schema_instance # (meaningless except for topmost call)
      end

  end
end
