require 'spec_helper'

RSpec.describe Scimitar::ResourceType do
  context '#as_json' do

    it 'adds the extensionSchemas' do
      resource_type = Scimitar::ResourceType.new(
        endpoint: '/Gaga',
        schema: 'urn:ietf:params:scim:schemas:core:2.0:User',
        schemaExtensions: ['urn:ietf:params:scim:schemas:extension:enterprise:2.0:User']
      )

      expect(resource_type.as_json['schemaExtensions']).to eql([{
        "schema" => 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User',
        "required" => false
      }])

    end

  end
end
