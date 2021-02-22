module Scimitar

  class NotFoundError < ErrorResponse

    def initialize(id)
      super(status: 404, detail: "Resource #{id} not found")
    end

  end
end
