module Scimitar
  class SchemasController < Scimitar::ApplicationController
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

      # Now we either have a simple render method, or a complex one.
      #
      schemas_to_render = if Scimitar.engine_configuration.schema_list_from_attribute_mappings.empty?
        list
      else
        self.redraw_schema_list_using_mappings(list)
      end

      render(json: {
        schemas: [
            'urn:ietf:params:scim:api:messages:2.0:ListResponse'
        ],
        totalResults: schemas_to_render.size,
        startIndex:   1,
        itemsPerPage: schemas_to_render.size,
        Resources:    schemas_to_render
      })
    end

    # =========================================================================
    # PRIVATE INSTANCE METHODS
    # =========================================================================
    #
    private

      # Given a list of schema *instances*, find all Scimitar::Resources::Mixin
      # inclusions to obtain classes with a ::scim_resource_type implementation
      # that is invoked to get at the associated Scimitar resource class; each
      # resource class then describes the schema it uses; the list is filtered
      # to include only those found schemas. Then, for each, use the discovered
      # class' attribute maps to walk the schema attribute tree alongside the
      # map and render only mapped attributes. This is done via calling down to
      # ::redraw_schema_using_mappings for each remaining schema in the list.
      #
      # An array of new schema data is returned.
      #
      # +list+:: Array of schema instances to examine.
      #
      def redraw_schema_list_using_mappings(list)

        # Iterate over the configured model classes to build a mapping from
        # Scimitar schema class to an array of one or more model classes that
        # seem to use it. This is to detect the error condition wherein some
        # schema gets used more than once, leading to multiple possible
        # attribute map choices.
        #
        classes_using_scimitar_mixin = Scimitar.engine_configuration.schema_list_from_attribute_mappings
        schema_to_resource_map       = {}

        classes_using_scimitar_mixin.each do | model_class |
          resource_class = model_class.scim_resource_type()
          schemas        = resource_class.extended_schemas + [resource_class.schema]

          schemas.each do | schema_class |
            schema_to_resource_map[schema_class] ||= []
            schema_to_resource_map[schema_class] <<  model_class
          end
        end

        # Take the schema list and map to rewritten versions based on finding
        # out which of the above resource classes use a given schema and then
        # walking this schema's attribute tree while comparing against the
        # resource class's attribute map. Unmapped attributes are removed. The
        # reality of resource class attribute mutability might give different
        # answers for the corresponding schema attribute's mutability; for any
        # custom schema we'd expect a match, but for core schema where local
        # resources don't quite work to spec, at least the /Schemas endpoint
        # can try to reflect reality and aid auto-discovery.
        #
        redrawn_list = list.map do | schema_instance |
          resource_classes_using_schema = schema_to_resource_map[schema_instance.class]

          if resource_classes_using_schema.nil?
            next # NOTE EARLY LOOP RESTART (schema not used by a resource)
          elsif resource_classes_using_schema.size > 1
            raise "Cannot infer attribute map for engine configuration 'schema_list_from_attribute_mappings: true' because multiple resource classes use schema '#{schema_instance.class.name}': #{resource_classes_using_schema.map(&:name).join(', ')}"
          end

          found_class = classes_using_scimitar_mixin.find do | class_using_scimitar_mixin |
            resource_class = class_using_scimitar_mixin.scim_resource_type()

            resource_class.schema == schema_instance.class ||
            resource_class.extended_schemas.include?(schema_instance.class)
          end

          rebuilt_schema_instance = if found_class
            redraw_schema_using_mappings(
              original_schema_instance: schema_instance,
              instance_including_mixin: found_class.new
            )
          else
            nil
          end

          rebuilt_schema_instance
        end

        redrawn_list.compact!
        redrawn_list
      end

      # "Redraw" a schema, by walking its attribute tree alongside a related
      # resource class's attribute map. Only mapped attributes are included.
      # The mapped model is checked for a read accessor and write ability is
      # determined via Scimitar::Resources::Mixin#scim_mutable_attributes. This
      # gives the actual read/write ability of the mapped attribute; if the
      # schema's declared mutability differs, the *most restrictive* is chosen.
      # For example, if the schema says read-write but the mapped model only
      # has read ability, then "readOnly" is used. Conversely, if the schema
      # says read-only but the mapped model has read-write, the schema's
      # "readOnly" is chosen instead as the source of truth.
      #
      # See the implementation's comments for a table describing exactly how
      # all mutability conflict cases are resolved.
      #
      # The returned schema instance may be a full or partial duplicate of the
      # one given on input - some or all attributes and/or sub-attributes may
      # have been duplicated due to e.g. mutability differences. Do not assume
      # or rely upon this as a caller.
      #
      # Mandatory named parameters for external callers are:
      #
      # +original_schema_instance+::   The Scimitar::Schema::Base subclass
      #                                schema *instance* that is to be examined
      #                                and possibly "redrawn".
      #
      # +instance_including_mixin+::   Instance of the model class including
      #                                Scimitar::Resources::Mixin, providing
      #                                the attribute map to be examined.
      #
      # Named parameters used internally for recursive calls are:
      #
      # +scim_attributes_map+::        The fragment of the attribute map found
      #                                from +instance_including_mixin+'s class
      #                                initially, which is relevant to the
      #                                current recursion level. E.g. it might
      #                                be the sub-attributes map of "name",
      #                                for things like a "familyName" mapping.
      #
      # +schema_attributes+::          An array of schema attributes for the
      #                                current recursion level, corresponding
      #                                to +scim_attributes_map+.
      #
      # +rebuilt_attribute_array+::    Redrawn schema attributes are collected
      #                                into this array, which is altered in
      #                                place. It is usually a 'subAttributes'
      #                                property of a schema attribute that's
      #                                provoked recursion in order to examine
      #                                and rebuild its sub-attributes directly.
      #
      def redraw_schema_using_mappings(
        original_schema_instance:,
        instance_including_mixin:,

        scim_attributes_map:     nil,
        schema_attributes:       nil,
        rebuilt_attribute_array: nil
      )
        schema_attributes   ||= original_schema_instance.scim_attributes
        scim_attributes_map ||= instance_including_mixin
          .class
          .scim_attributes_map()
          .with_indifferent_case_insensitive_access()

        rebuilt_schema_instance = nil

        if rebuilt_attribute_array.nil?
          rebuilt_schema_instance                 = self.duplicate_attribute(original_schema_instance)
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
                  instance_including_mixin.is_a?(ActiveRecord::Base)
                )
                  associated_resource_class = instance_including_mixin
                    .class
                    .reflect_on_association(mapped_multivalue_attribute.first[:list])
                    &.klass
                end

                if associated_resource_class.nil? || ! associated_resource_class.include?(Scimitar::Resources::Mixin)
                  rebuilt_attribute_array << schema_attribute
                else
                  rebuilt_schema_attribute = self.duplicate_attribute(schema_attribute)
                  rebuilt_schema_attribute.subAttributes = []
                  rebuilt_attribute_array << rebuilt_schema_attribute

                  redraw_schema_using_mappings(
                    original_schema_instance: original_schema_instance,
                    instance_including_mixin: associated_resource_class.new,
                    scim_attributes_map:      mapped_multivalue_attribute.first[:using],
                    schema_attributes:        schema_attribute.subAttributes,
                    rebuilt_attribute_array:  rebuilt_schema_attribute.subAttributes
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

                rebuilt_schema_attribute = self.duplicate_attribute(schema_attribute)
                rebuilt_schema_attribute.subAttributes = []
                rebuilt_attribute_array << rebuilt_schema_attribute

                redraw_schema_using_mappings(
                  original_schema_instance: original_schema_instance,
                  instance_including_mixin: instance_including_mixin,
                  scim_attributes_map:      union_of_mappings,
                  schema_attributes:        schema_attribute.subAttributes,
                  rebuilt_attribute_array:  rebuilt_schema_attribute.subAttributes
                )
              end
            end

          elsif schema_attribute.subAttributes&.any?
            mapped_subattributes = scim_attributes_map[schema_attribute.name]

            if mapped_subattributes.is_a?(Hash)
              rebuilt_schema_attribute = self.duplicate_attribute(schema_attribute)
              rebuilt_schema_attribute.subAttributes = []
              rebuilt_attribute_array << rebuilt_schema_attribute

              redraw_schema_using_mappings(
                original_schema_instance: original_schema_instance,
                instance_including_mixin: instance_including_mixin,
                scim_attributes_map:      mapped_subattributes,
                schema_attributes:        schema_attribute.subAttributes,
                rebuilt_attribute_array:  rebuilt_schema_attribute.subAttributes
              )
            end

          else
            mapped_attribute = scim_attributes_map[schema_attribute.name]

            unless mapped_attribute.nil?
              rebuilt_schema_attribute = self.duplicate_attribute(schema_attribute)
              has_mapped_reader        = true
              has_mapped_writer        = false

              if mapped_attribute.is_a?(String) || mapped_attribute.is_a?(Symbol)
                has_mapped_reader = instance_including_mixin.respond_to?(mapped_attribute)
                has_mapped_writer = instance_including_mixin.scim_mutable_attributes().include?(mapped_attribute.to_sym)
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

      # Small helper that duplicates Scimitar::Schema::Attribute instances, but
      # then removes their 'errors' collection which otherwise gets initialised
      # to an empty value and is rendered as if part of the schema (which isn't
      # a valid entry in a SCIM schema representation).
      #
      # +schema_attribute+:: Scimitar::Schema::Attribute to be duplicated.
      #                      A renderable duplicate is returned.
      #
      def duplicate_attribute(schema_attribute)
        duplicated_schema_attribute = schema_attribute.dup()
        duplicated_schema_attribute.remove_instance_variable('@errors')
        duplicated_schema_attribute
      end

  end
end
