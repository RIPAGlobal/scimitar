module Scimitar
  module ComplexTypes

    # Represents the complex PhoneNumber type.
    #
    # @see Scimitar::Schema::PhoneNumber
    #
    class PhoneNumber < Base
      set_schema Scimitar::Schema::PhoneNumber

      # Returns the JSON representation of a PhoneNumber.
      #
      def as_json(options = {})
        {'type' => 'work'}.merge(super(options))
      end
    end
  end
end
