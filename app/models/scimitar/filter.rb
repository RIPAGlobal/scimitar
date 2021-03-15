module Scimitar

  # Used to configure filters via
  # app/models/scimitar/service_provider_configuration.rb.
  #
  class Filter < Supportable
    MAX_RESULTS_DEFAULT = 100

    attr_accessor :maxResults
  end
end
