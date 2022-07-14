module Scimitar
  class ErrorResponse < StandardError
    include ActiveModel::Model

    attr_accessor :status,
                  :detail,
                  :scimType

    def as_json(options = {})
      data = {
        'schemas': ['urn:ietf:params:scim:api:messages:2.0:Error'],
        'detail': detail,
        'status': "#{status}"
      }

      data['scimType'] = scimType if scimType
      data
    end

    # From v1, Scimitar used attribute "detail" for the exception text; it was
    # only for JSON responses at the time, but in hindsight was a bad choice.
    # It should have been "message" given inheritance from StandardError, which
    # then works properly with e.g. error reporting services.
    #
    # The "detail" attribute is still present, for backwards compatibility with
    # any client code that might be using this class.
    #
    def message
      self.detail
    end
  end
end
