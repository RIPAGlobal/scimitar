require 'rails/engine'

module Scimitar
  class Engine < ::Rails::Engine
    isolate_namespace Scimitar

    config.autoload_once_paths = %W(
      #{root}/app/controllers
      #{root}/app/models
    )

    Mime::Type.register 'application/scim+json', :scim

    ActionDispatch::Request.parameter_parsers[Mime::Type.lookup('application/scim+json').symbol] = lambda do |body|
      JSON.parse(body)
    end

    def self.resources
      default_resources + custom_resources
    end

    # Can be used to add a new resource type which is not provided by the gem.
    # For example:
    #
    #     module Scim
    #       module Resources
    #         class ShinyResource < Scimitar::Resources::Base
    #           set_schema Scim::Schema::Shiny
    #
    #           def self.endpoint
    #             "/Shinies"
    #           end
    #         end
    #       end
    #     end
    #
    #     Scimitar::Engine.add_custom_resource Scim::Resources::ShinyResource
    #
    def self.add_custom_resource(resource)
      custom_resources << resource
    end

    # Resets the resource list to default. This is really only intended for use
    # during testing, to avoid one test polluting another.
    #
    def self.reset_custom_resources
      @custom_resources = []
    end

    # Returns the list of custom resources, if any.
    #
    def self.custom_resources
      @custom_resources ||= []
    end

    # Returns the default resources added in this gem:
    #
    # * Scimitar::Resources::User
    # * Scimitar::Resources::Group
    #
    def self.default_resources
      [ Resources::User, Resources::Group ]
    end

    def self.schemas
      resources.map(&:schemas).flatten.uniq.map(&:new)
    end

  end
end
