require 'spec_helper'

RSpec.describe Scimitar::Schema::User do
  let(:expected_attributes) {
    <<-EOJ
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
        "required": false,
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
            "name": "middleName",
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
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "honorificPrefix",
            "type": "string"
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "honorificSuffix",
            "type": "string"
          }
        ]
      },

      {
        "multiValued": false,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "displayName",
        "type": "string"
      },
      {
        "multiValued": false,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "nickName",
        "type": "string"
      },
      {
        "multiValued": false,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "profileUrl",
        "type": "string"
      },
      {
        "multiValued": false,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "title",
        "type": "string"
      },
      {
        "multiValued": false,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "userType",
        "type": "string"
      },
      {
        "multiValued": false,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "preferredLanguage",
        "type": "string"
      },
      {
        "multiValued": false,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "locale",
        "type": "string"
      },
      {
        "multiValued": false,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "timezone",
        "type": "string"
      },

      {
        "multiValued": false,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "active",
        "type": "boolean"
      },

      {
        "multiValued": false,
        "required": false,
        "caseExact": false,
        "mutability": "writeOnly",
        "uniqueness": "none",
        "returned": "never",
        "name": "password",
        "type": "string"
      },

      {
        "multiValued": true,
        "required": false,
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
            "mutability": "readOnly",
            "uniqueness": "none",
            "returned": "default",
            "name": "display",
            "type": "string"
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
          }
        ]
      },
      {
        "multiValued": true,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "phoneNumbers",
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
            "mutability": "readOnly",
            "uniqueness": "none",
            "returned": "default",
            "name": "display",
            "type": "string"
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
          }
        ]
      },
      {
        "multiValued": true,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "ims",
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
            "mutability": "readOnly",
            "uniqueness": "none",
            "returned": "default",
            "name": "display",
            "type": "string"
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
          }
        ]
      },
      {
        "multiValued": true,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "photos",
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
            "mutability": "readOnly",
            "uniqueness": "none",
            "returned": "default",
            "name": "display",
            "type": "string"
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
          }
        ]
      },
      {
        "multiValued": true,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "addresses",
        "type": "complex",
        "subAttributes": [
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "type",
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
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "streetAddress",
            "type": "string"
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "locality",
            "type": "string"
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "region",
            "type": "string"
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "postalCode",
            "type": "string"
          },
          {
            "multiValued": false,
            "required": false,
            "caseExact": false,
            "mutability": "readWrite",
            "uniqueness": "none",
            "returned": "default",
            "name": "country",
            "type": "string"
          }
        ]
      },
      {
        "multiValued": true,
        "required": false,
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
            "name": "display",
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
      },
      {
        "multiValued": true,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "entitlements",
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
            "mutability": "readOnly",
            "uniqueness": "none",
            "returned": "default",
            "name": "display",
            "type": "string"
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
          }
        ]
      },
      {
        "multiValued": true,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "roles",
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
            "mutability": "readOnly",
            "uniqueness": "none",
            "returned": "default",
            "name": "display",
            "type": "string"
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
          }
        ]
      },
      {
        "multiValued": true,
        "required": false,
        "caseExact": false,
        "mutability": "readWrite",
        "uniqueness": "none",
        "returned": "default",
        "name": "x509Certificates",
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
            "type": "binary"
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
          }
        ]
      }
    ]
    EOJ
  }

  let(:expected_full_schema) {
    <<-EOJ
      {
        "name": "User",
        "id": "urn:ietf:params:scim:schemas:core:2.0:User",
        "description": "Represents a User",
        "meta": {
          "resourceType": "Schema",
          "location": "/scim/Schemas?name=urn%3Aietf%3Aparams%3Ascim%3Aschemas%3Acore%3A2.0%3AUser"
        },
        "attributes": #{expected_attributes()}
      }
    EOJ
  }

  it 'returns User schema as JSON' do
    actual_full_schema = Scimitar::Schema::User.new
    expect(JSON.parse(expected_full_schema())).to eql(JSON.parse(actual_full_schema.to_json))
  end

  it 'returns the schema attributes as JSON' do
    actual_attributes = Scimitar::Schema::User.scim_attributes
    expect(JSON.parse(expected_attributes())).to eql(JSON.parse(actual_attributes.to_json))
  end
end
