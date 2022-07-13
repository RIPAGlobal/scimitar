module Scimitar

  # Scimitar general configuration.
  #
  # See config/initializers/scimitar.rb for more information.
  #
  class EngineConfiguration
    include ActiveModel::Model

    attr_accessor :basic_authenticator,
                  :token_authenticator,
                  :application_controller_mixin,
                  :optional_value_fields_required


    def initialize(attributes = {})

      # Set defaults that may be overridden by the initializer.
      #
      defaults = {
        optional_value_fields_required: true
      }

      super(defaults.merge(attributes))
    end

  end
end
