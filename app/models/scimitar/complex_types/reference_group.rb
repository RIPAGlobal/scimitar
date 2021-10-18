module Scimitar
  module ComplexTypes

    # Represents the complex reference-a-group type.
    #
    # See also Scimitar::Schema::ReferenceGroup
    #
    class ReferenceGroup < Scimitar::ComplexTypes::Base
      set_schema Scimitar::Schema::ReferenceGroup
    end
  end
end
