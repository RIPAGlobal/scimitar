module Scimitar
  module ComplexTypes

    # Represents the complex Email type.
    #
    # @see Scimitar::Schema::Email
    #
    class Email < Base
      set_schema Scimitar::Schema::Email

      # Returns the JSON representation of an Email.
      #
      def as_json(options = {})
        {'type' => 'work', 'primary' => true}.merge(super(options))
      end
    end
  end
end
