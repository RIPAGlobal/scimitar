module Scimitar
  class ErrorResponse < StandardError
    include ActiveModel::Model

    attr_accessor :status, :detail, :scimType

    def as_json(options = {})
      {'schemas': ['urn:ietf:params:scim:api:messages:2.0:Error'],
      'detail': detail,
      'status': "#{status}"}.merge(scimType ? {'scimType': scimType} : {})
    end
  end
end
