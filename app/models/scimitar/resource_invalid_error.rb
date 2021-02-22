module Scimitar
  class ResourceInvalidError < ErrorResponse

    def initialize(error_message)
      super(status: 400, scimType: 'invalidValue', detail:"Operation failed since record has become invalid: #{error_message}")
    end

  end
end
