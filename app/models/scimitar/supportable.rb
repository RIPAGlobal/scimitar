module Scimitar
  class Supportable
    include ActiveModel::Model
    attr_accessor :supported

    def self.unsupported
      new(supported: false)
    end
  end
end
