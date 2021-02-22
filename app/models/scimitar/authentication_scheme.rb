module Scimitar
  class AuthenticationScheme
    include ActiveModel::Model
    attr_accessor :type, :name, :description

    def self.basic
      new type: 'httpbasic',
        name: 'HTTP Basic',
        description: 'Authentication scheme using the HTTP Basic Standard'
    end
  end
end
