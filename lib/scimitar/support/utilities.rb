module Scimitar

  # Namespace containing various chunks of Scimitar support code that don't
  # logically fit into other areas.
  #
  module Support

    # A namespace that contains various stand-alone utility methods which act
    # as helpers for other parts of the code base, without risking namespace
    # pollution by e.g. being part of a module loaded into a client class.
    #
    module Utilities

      # Takes an array of components that usually come from a dotted path such
      # as <tt>foo.bar.baz</tt>, along with a value that is found at the end of
      # that path, then converts it into a nested Hash with each level of the
      # Hash corresponding to a step along the path.
      #
      # This was written to help with edge case SCIM uses where (most often, at
      # least) inbound calls use a dotted notation where nested values are more
      # commonly accepted; converting to nesting makes it easier for subsequent
      # processing code, which needs only handle nested Hash data.
      #
      # As an example, passing:
      #
      #     ['foo', 'bar', 'baz'], 'value'
      #
      # ...yields:
      #
      #     {'foo' => {'bar' => {'baz' => 'value'}}}
      #
      # Parameters:
      #
      # +array+:: Array containing path components, usually acquired from a
      #           string with dot separators and a call to String#split.
      #
      # +value+:: The value found at the path indicated by +array+.
      #
      # If +array+ is empty, +value+ is returned directly, with no nesting
      # Hash wrapping it.
      #
      def self.dot_path(array, value)
        return value if array.empty?

        {}.tap do | hash |
          hash[array.shift()] = self.dot_path(array, value)
        end
      end

      # Schema ID-aware splitter handling ":" or "." separators. Adapted from
      # contribution by @bettysteger and @MorrisFreeman in:
      #
      #   https://github.com/RIPAGlobal/scimitar/issues/48
      #   https://github.com/RIPAGlobal/scimitar/pull/49
      #
      # +schemas::   Array of extension schemas, e.g. a SCIM resource class'
      #              <tt>scim_resource_type.extended_schemas</tt> value. The
      #              Array should be empty if there are no extensions.
      #
      # +path_str+:: Path string, e.g. <tt>"password"</tt>, <tt>"name.givenName"</tt>,
      #              <tt>"urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"</tt> (special case),
      #              <tt>"urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:organization"</tt>
      #
      # Returns an array of components, e.g. <tt>["password"]</tt>, <tt>["name",
      # "givenName"]</tt>,
      # <tt>["urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"]</tt> (special case),
      # <tt>["urn:ietf:params:scim:schemas:extension:enterprise:2.0:User", "organization"]</tt>.
      #
      # The called-out special case is for a schema ID without any appended
      # path components, which is returned as a single element ID to aid in
      # traversal particularly of things like PATCH requests. There, a "value"
      # attribute might have a key string that's simply a schema ID, with an
      # object beneath that's got attribute-name pairs, possibly nested, in a
      # path-free payload. SCIM is... Over-complicated.
      #
      def self.path_str_to_array(schemas, path_str)
        components = []

        # Note the ":" separating the schema ID (URN) from the attribute.
        # The nature of JSON rendering / other payloads might lead you to
        # expect a "." as with any complex types, but that's not the case;
        # see https://tools.ietf.org/html/rfc7644#section-3.10, or
        # https://tools.ietf.org/html/rfc7644#section-3.5.2 of which in
        # particular, https://tools.ietf.org/html/rfc7644#page-35.
        #
        if path_str.include?(':')
          schemas.each do |schema|
            attributes_after_schema_id = path_str.downcase.split(schema.id.downcase + ':').drop(1)

            if attributes_after_schema_id.empty?
              components += [schema.id]
            else
              attributes_after_schema_id.each do |component|
                components += [schema.id] + component.split('.')
              end
            end
          end
        end

        components = path_str.split('.') if components.empty?
        return components
      end

    end
  end
end
