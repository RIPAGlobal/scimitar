module Scimitar

  # Represents the service provider info. Used by the /ServiceProviderConfig
  # endpoint to provide specification compliance, authentication schemes and
  # data models. Renders to JSON as a SCIM ServiceProviderConfig type.
  #
  # See config/initializers/scimitar.rb for more information.
  #
  class ServiceProviderConfiguration
    include ActiveModel::Model

    attr_accessor :patch, :bulk, :filter, :changePassword,
      :sort, :etag, :authenticationSchemes,
      :schemas, :meta

    def initialize(attributes = {})
      defaults = {
        bulk:           Supportable.unsupported,
        changePassword: Supportable.unsupported,
        sort:           Supportable.unsupported,
        etag:           Supportable.unsupported,

        patch: Supportable.supported,

        filter: Scimitar::Filter.new(
          supported:  true,
          maxResults: Scimitar::Filter::MAX_RESULTS_DEFAULT
        ),

        schemas: ["urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"],

        meta: Meta.new(
          resourceType: 'ServiceProviderConfig',
          created:      Time.now,
          lastModified: Time.now,
          version:      '1'
        ),

        authenticationSchemes: [
          AuthenticationScheme.basic,
          AuthenticationScheme.bearer
        ]
      }

      super(defaults.merge(attributes))
    end

  end
end
