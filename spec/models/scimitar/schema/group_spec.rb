require 'spec_helper'

RSpec.describe Scimitar::Schema::Group do
  let(:expected_attributes) {
    <<-EOJ
    [
      {
        "multiValued": false,
        "required": true,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "displayName",
        "type": "string"
      },
      {
        "multiValued": true,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "members",
        "type": "complex",
        "subAttributes": [
          {
            "multiValued": false,
            "required": true,
            "caseExact": false,
            "mutability": "immutable",
            "uniqueness": "none",
            "returned": "default",
            "name": "value",
            "type": "string"
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "immutable",
            "uniqueness": "none",
            "returned": "default",
            "name": "type",
            "type": "string"
          }
        ]
      }
    ]
    EOJ
  }

  let(:expected_full_schema) {
    <<-EOJ
      {
        "name": "Group",
        "id": "urn:ietf:params:scim:schemas:core:2.0:Group",
        "description": "Represents a Group",
        "meta": {
          "resourceType": "Schema",
          "location": "/Schemas?name=urn%3Aietf%3Aparams%3Ascim%3Aschemas%3Acore%3A2.0%3AGroup"
        },
        "attributes": #{expected_attributes()}
      }
    EOJ
  }

  it 'returns Group schema as JSON' do
    actual_full_schema = Scimitar::Schema::Group.new
    expect(JSON.parse(actual_full_schema.to_json)).to eql(JSON.parse(expected_full_schema()))
  end

  it 'returns the schema attributes as JSON' do
    actual_attributes = Scimitar::Schema::Group.scim_attributes
    expect(JSON.parse(actual_attributes.to_json)).to eql(JSON.parse(expected_attributes()))
  end
end
