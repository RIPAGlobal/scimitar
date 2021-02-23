module Scimitar
  class AuthenticationScheme
    include ActiveModel::Model
    attr_accessor :type, :name, :description

    def self.basic
      new type:        'httpbasic',
          name:        'HTTP Basic',
          description: 'Authentication scheme using the HTTP Basic Standard'
    end

    def self.bearer
      new type:        'oauthbearertoken',
          name:        'OAuth Bearer Token',
          description: 'Authentication scheme using the OAuth Bearer Token Standard'
    end
  end
end
