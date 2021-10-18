module Scimitar
  module ComplexTypes

    # Represents the complex reference-a-member type.
    #
    # See also Scimitar::Schema::ReferenceMember
    #
    class ReferenceMember < Scimitar::ComplexTypes::Base
      set_schema Scimitar::Schema::ReferenceMember
    end
  end
end
