# Test app configuration.
#
# Note that as a result of https://github.com/RIPAGlobal/scimitar/issues/48,
# tests include a custom extension of the core User schema. A shortcoming of
# some of the code from which Scimitar was originally built is that those
# extensions are done with class-level ivars, so it is largely impossible (or
# at least, impractical in tests) to avoid polluting the core class itself
# with the extension.
#
# All related schema tests are written with this in mind.
#
Rails.application.config.to_prepare do
  Scimitar.engine_configuration = Scimitar::EngineConfiguration.new({

    application_controller_mixin: Module.new do
      def self.included(base)
        base.class_eval do
          def test_hook; end
          before_action :test_hook
        end
      end

      def scim_schemas_url(options)
        super(test: 1, **options)
      end

      def scim_resource_type_url(options)
        super(test: 1, **options)
      end
    end

  })

  module ScimSchemaExtensions
    module User

      # This "looks like" part of the standard Enterprise extension.
      #
      class Enterprise < Scimitar::Schema::Base
        def initialize(options = {})
          super(
            name:            'EnterpriseExtendedUser',
            description:     'Enterprise extension for a User',
            id:              self.class.id,
            scim_attributes: self.class.scim_attributes
          )
        end

        def self.id
          'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User'
        end

        def self.scim_attributes
          [
            Scimitar::Schema::Attribute.new(name: 'organization', type: 'string'),
            Scimitar::Schema::Attribute.new(name: 'department',   type: 'string'),
            Scimitar::Schema::Attribute.new(name: 'primaryEmail', type: 'string'),
          ]
        end
      end

      # In https://github.com/RIPAGlobal/scimitar/issues/122 we learn that with
      # more than one extension, things can go wrong - so now we test with two.
      #
      class Manager < Scimitar::Schema::Base
        def initialize(options = {})
          super(
            name:            'ManagementExtendedUser',
            description:     'Management extension for a User',
            id:              self.class.id,
            scim_attributes: self.class.scim_attributes
          )
        end

        def self.id
          'urn:ietf:params:scim:schemas:extension:manager:1.0:User'
        end

        def self.scim_attributes
          [
            Scimitar::Schema::Attribute.new(name: 'manager', type: 'string')
          ]
        end
      end
    end
  end

  Scimitar::Resources::User.extend_schema ScimSchemaExtensions::User::Enterprise
  Scimitar::Resources::User.extend_schema ScimSchemaExtensions::User::Manager
end
