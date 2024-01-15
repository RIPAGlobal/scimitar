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
    end
  end
end
