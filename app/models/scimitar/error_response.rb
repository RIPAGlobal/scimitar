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
  end
end
