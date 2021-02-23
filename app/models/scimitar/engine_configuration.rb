module Scimitar

  # Scimitar general configuration.
  #
  # See config/initializers/scimitar.rb for more information.
  #
  class EngineConfiguration
    include ActiveModel::Model

    attr_accessor :basic_authenticator,
                  :token_authenticator

    def initialize(attributes = {})

      # No defaults yet - reserved for future use.
      #
      defaults = {}

      super(defaults.merge(attributes))
    end

  end
end
