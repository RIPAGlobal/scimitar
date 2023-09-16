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
# Further, https://github.com/RIPAGlobal/scimitar/pull/54 fixed warning
# messages in a way that worked on Rails 6+ but backported for V1, it would
# break existing working setups that didn't use the "to_prepare" wrapper since
# that would mean their own configuration got written *first* but then
# *overwritten* by the default "to_prepare" block in Scimitar itself, since
# that runs later. The file below does *not* use "to_prepare" in order to test
# the workaround that was produced; it should work on all Ruby versions as-is.
#
Scimitar.engine_configuration = Scimitar::EngineConfiguration.new({

  application_controller_mixin: Module.new do
    def self.included(base)
      base.class_eval do
        def test_hook; end
        before_action :test_hook
      end
    end
  end

})

module ScimSchemaExtensions
  module User
    class Enterprise < Scimitar::Schema::Base
      def initialize(options = {})
        super(
          name:            'ExtendedUser',
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
          Scimitar::Schema::Attribute.new(name: 'department',   type: 'string')
        ]
      end
    end
  end
end

Scimitar::Resources::User.extend_schema ScimSchemaExtensions::User::Enterprise
