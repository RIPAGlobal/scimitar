module Scimitar

  class AuthenticationError < ErrorResponse
    def initialize
      super(status: 401, detail: 'Requires authentication')
    end

  end
end
