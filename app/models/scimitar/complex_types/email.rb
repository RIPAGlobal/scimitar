module Scimitar
  module ComplexTypes

    # Represents the complex Email type.
    #
    # See also Scimitar::Schema::Email
    #
    class Email < Scimitar::ComplexTypes::Base
      set_schema Scimitar::Schema::Email
    end
  end
end
