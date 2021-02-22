module Scimitar
  module ComplexTypes
    # Represents the complex email type.
    # @see Scimitar::Schema::Email
    class Email < Base
      set_schema Scimitar::Schema::Email

      # Returns the json representation of an email.
      def as_json(options = {})
        {'type' => 'work', 'primary' => true}.merge(super(options))
      end
    end
  end
end
