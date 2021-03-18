# Test app configuration.
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
