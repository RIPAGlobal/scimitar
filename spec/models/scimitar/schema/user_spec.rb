require 'spec_helper'

RSpec.describe Scimitar::Schema::User do
  it 'returns User schema as JSON' do
    expected_json = <<-EOJ
    [
      {
        "multiValued": false,
        "required": true,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "server",
        "returned": "default",
        "name": "userName",
        "type": "string"
      },
      {
        "multiValued": false,
        "required": true,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "name",
        "type": "complex",
        "subAttributes": [
          {
            "multiValued": false,
            "required": true,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "familyName",
            "type": "string"
          },
          {
            "multiValued": false,
            "required": true,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "givenName",
            "type": "string"
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "formatted",
            "type": "string"
          }
        ]
      },
      {
        "multiValued": true,
        "required": true,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "emails",
        "type": "complex",
        "subAttributes": [
          {
            "multiValued": false,
            "required": true,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "value",
            "type": "string"
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "primary",
            "type": "boolean"
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "type",
            "type": "string"
          }
        ]
      },
      {
        "multiValued": true,
        "required": true,
        "caseExact": false,
        "mutability": "immutable",
        "uniqueness": "none",
        "returned": "default",
        "name": "groups",
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
    EOJ

    expect(JSON.parse(expected_json)).to eql(JSON.parse(Scimitar::Schema::User.scim_attributes.to_json))

  end

end
