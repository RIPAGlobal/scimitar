module Scimitar
  module ComplexTypes

    # Represents the complex Instant Messaging type.
    #
    # See also Scimitar::Schema::Ims
    #
    class Ims < Scimitar::ComplexTypes::Base
      set_schema Scimitar::Schema::Ims
    end
  end
end
