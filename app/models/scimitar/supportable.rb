module Scimitar
  class Supportable
    include ActiveModel::Model
    attr_accessor :supported

    def self.supported
      new(supported: true)
    end

    def self.unsupported
      new(supported: false)
    end
  end
end
