module Scimitar
  class Meta
    include ActiveModel::Model

    attr_accessor :resourceType, :created, :lastModified, :location, :version
  end
end
