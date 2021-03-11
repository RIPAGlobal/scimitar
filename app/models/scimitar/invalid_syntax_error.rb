module Scimitar
  class InvalidSyntaxError < ErrorResponse

    def initialize(error_message)
      super(status: 400, scimType: 'invalidSyntax', detail: error_message)
    end

  end
end
