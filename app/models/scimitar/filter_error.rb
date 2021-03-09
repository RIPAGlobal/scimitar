module Scimitar

  # Raised when an invalid query is attempted, either by being malformed or by
  # being unsupported in some way.
  #
  class FilterError < ErrorResponse
    def initialize(message = nil)
      detail = 'The specified filter syntax was invalid, or the specified attribute and filter comparison combination is not supported'

      if message.present?
        detail << ":\n#{message}"
      end

      super(
        status:   400,
        scimType: 'invalidFilter',
        detail:   detail
      )
    end
  end

end
