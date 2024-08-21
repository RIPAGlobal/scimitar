module Scimitar
  # Provides info about a resource type. Instances of this class are used to provide info through the /ResourceTypes endpoint of a SCIM service provider.
  class ResourceType
    include ActiveModel::Model
    attr_accessor :meta, :endpoint, :schema, :schemas, :id, :name, :schemaExtensions

    def initialize(attributes = {})
      default_attributes = {
        meta: Meta.new(
          'resourceType': 'ResourceType'
        ),
        schemas: ['urn:ietf:params:scim:schemas:core:2.0:ResourceType']
      }
      super(default_attributes.merge(attributes))
    end


    def as_json(options = {})
      without_extensions = super(except: 'schemaExtensions')
      return without_extensions unless schemaExtensions.present?

      extensions = schemaExtensions.map{|extension| {"schema" => extension, "required" => false}}
      without_extensions.merge('schemaExtensions' => extensions)
    end

  end
end
