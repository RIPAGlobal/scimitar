# SCIMITAR CONFIGURATION
#
# For supporting information and rationale, please see README.md.

# =============================================================================
# SERVICE PROVIDER CONFIGURATION
# =============================================================================
#
# This is a Ruby abstraction over a SCIM entity that declares the capabilities
# supported by a particular implementation.
#
# Typically this is used to declare parts of the standard unsupported, if you
# don't need them and don't want to provide subclass support.
#
Scimitar.service_provider_configuration = Scimitar::ServiceProviderConfiguration.new({

  # See https://tools.ietf.org/html/rfc7643#section-8.5 for properties.
  #
  # See Gem source file 'app/models/scimitar/service_provider_configuration.rb'
  # for defaults. Define Hash keys here that override defaults; e.g. to declare
  # that filters are not supported so that calling clients shouldn't use them:
  #
  #   filter: Scimitar::Supported.unsupported

})

# =============================================================================
# ENGINE CONFIGURATION
# =============================================================================
#
# This is where you provide callbacks for things like authorisation.
#
Scimitar.engine_configuration = Scimitar::EngineConfiguration.new({

  # If you want to support username/password authentication:
  #
  #     basic_authenticator: Proc.new do | username, password |
  #       # Check username/password and return 'true' if valid, else 'false'.
  #     end
  #
  # The 'username' and 'password' parameters come from Rails:
  #
  #   https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Basic.html
  #   https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Basic/ControllerMethods.html#method-i-authenticate_with_http_basic

  # If you want to support HTTP bearer token (OAuth-style) authentication:
  #
  #     token_authenticator: Proc.new do | token, options |
  #       # Check token and return 'true' if valid, else 'false'.
  #     end
  #
  # The 'token' and 'options' parameters come from Rails:
  #
  #   https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token.html
  #   https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token/ControllerMethods.html#method-i-authenticate_with_http_token
  #
  # Note that both basic and token authentication can be declared, with the
  # parameters in the inbound HTTP request determining which is invoked.

})
