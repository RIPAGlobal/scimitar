module Scimitar
  module ComplexTypes

    # Represents the complex Address type.
    #
    # See also Scimitar::Schema::Address
    #
    class Address < Base
      set_schema Scimitar::Schema::Address

      # Returns the JSON representation of an Address.
      #
      def as_json(options = {})
        {'type' => 'work'}.merge(super(options))
      end
    end
  end
end
