require 'spec_helper'

RSpec.describe Scimitar::Schema::Group do
  it 'returns Group schema as JSON' do
    expected_json = <<-EOJ
    {
    "name": "Group",
    "id": "urn:ietf:params:scim:schemas:core:2.0:Group",
    "description": "Represents a Group",
    "meta": {
      "resourceType": "Schema",
      "location": "/scimitar/Schemas?name=urn%3Aietf%3Aparams%3Ascim%3Aschemas%3Acore%3A2.0%3AGroup"
    },
    "attributes": [
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
        "mutability": "readOnly",
        "uniqueness": "none",
        "returned": "default",
        "name": "members",
        "type": "complex",
        "subAttributes": [
          {
            "multiValued": false,
            "required": true,
            "caseExact": false,
            "mutability": "readOnly",
            "uniqueness": "none",
            "returned": "default",
            "name": "value",
            "type": "string"
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readOnly",
            "uniqueness": "none",
            "returned": "default",
            "name": "display",
            "type": "string"
          }
        ]
      }
    ]
  }
    EOJ

    group_schema = Scimitar::Schema::Group.new

    expect(JSON.parse(expected_json)).to eql(JSON.parse(group_schema.to_json))

  end
end
