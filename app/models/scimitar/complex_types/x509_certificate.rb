module Scimitar
  module ComplexTypes

    # Represents the complex X509Certificate type.
    #
    # See also Scimitar::Schema::X509Certificate
    #
    class X509Certificate < Base
      set_schema Scimitar::Schema::X509Certificate
    end
  end
end
