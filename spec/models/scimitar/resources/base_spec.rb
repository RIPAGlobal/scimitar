require 'spec_helper'

RSpec.describe Scimitar::Resources::Base do
  context 'basic operation' do
    FirstCustomSchema = Class.new(Scimitar::Schema::Base) do
      def self.id
        'custom-id'
      end

      def self.scim_attributes
        [
          Scimitar::Schema::Attribute.new(
            name: 'name', complexType: Scimitar::ComplexTypes::Name, required: false
          ),
          Scimitar::Schema::Attribute.new(
            name: 'names', multiValued: true, complexType: Scimitar::ComplexTypes::Name, required: false
          ),
          Scimitar::Schema::Attribute.new(
            name: 'privateName', complexType: Scimitar::ComplexTypes::Name, required: false, returned: 'never'
          ),
        ]
      end
    end

    CustomResourse = Class.new(Scimitar::Resources::Base) do
      set_schema FirstCustomSchema
    end

    context '#initialize' do
      it 'accepts nil for non-required attributes' do
        resource = CustomResourse.new(name: nil, names: nil, privateName: nil)

        expect(resource.name).to be_nil
        expect(resource.names).to be_nil
        expect(resource.privateName).to be_nil
      end

      shared_examples 'an initializer' do | force_upper_case: |
        it 'which builds the nested type' do
          attributes = {
            name: {
              givenName:  'John',
              familyName: 'Smith'
            },
            privateName: {
              givenName:  'Alt John',
              familyName: 'Alt Smith'
            }
          }

          attributes = spec_helper_hupcase(attributes) if force_upper_case
          resource   = CustomResourse.new(attributes)

          expect(resource.name.is_a?(Scimitar::ComplexTypes::Name)).to be(true)
          expect(resource.name.givenName).to eql('John')
          expect(resource.name.familyName).to eql('Smith')
          expect(resource.privateName.is_a?(Scimitar::ComplexTypes::Name)).to be(true)
          expect(resource.privateName.givenName).to eql('Alt John')
          expect(resource.privateName.familyName).to eql('Alt Smith')
        end

        it 'which builds an array of nested resources' do
          attributes = {
            names:[
              {
                givenName:  'John',
                familyName: 'Smith'
              },
              {
                givenName:  'Jane',
                familyName: 'Snow'
              }
            ]
          }

          attributes = spec_helper_hupcase(attributes) if force_upper_case
          resource   = CustomResourse.new(attributes)

          expect(resource.names.is_a?(Array)).to be(true)
          expect(resource.names.first.is_a?(Scimitar::ComplexTypes::Name)).to be(true)
          expect(resource.names.first.givenName).to eql('John')
          expect(resource.names.first.familyName).to eql('Smith')
          expect(resource.names.second.is_a?(Scimitar::ComplexTypes::Name)).to be(true)
          expect(resource.names.second.givenName).to eql('Jane')
          expect(resource.names.second.familyName).to eql('Snow')
          expect(resource.valid?).to be(true)
        end

        it 'which builds an array of nested resources which is invalid if the hash does not follow the schema of the complex type' do
          attributes = {
            names: [
              {
                givenName:  'John',
                familyName: 123
              }
            ]
          }

          attributes = spec_helper_hupcase(attributes) if force_upper_case
          resource   = CustomResourse.new(attributes)

          expect(resource.names.is_a?(Array)).to be(true)
          expect(resource.names.first.is_a?(Scimitar::ComplexTypes::Name)).to be(true)
          expect(resource.names.first.givenName).to eql('John')
          expect(resource.names.first.familyName).to eql(123)
          expect(resource.valid?).to be(false)
        end
      end # "shared_examples 'an initializer' do | force_upper_case: |"

      context 'using schema-matched case' do
        it_behaves_like 'an initializer', force_upper_case: false
      end # "context 'using schema-matched case' do"

      context 'using upper case' do
        it_behaves_like 'an initializer', force_upper_case: true
      end # "context 'using upper case' do"
    end # "context '#initialize' do"

    context '#as_json' do
      it 'renders the json with the resourceType' do
        resource = CustomResourse.new(name: {
          givenName:  'John',
          familyName: 'Smith'
        })

        result = resource.as_json

        expect(result['schemas']             ).to eql(['custom-id'])
        expect(result['meta']['resourceType']).to eql('CustomResourse')
        expect(result['errors']              ).to be_nil
      end

      it 'excludes attributes that are flagged as do-not-return' do
        resource = CustomResourse.new(
          name: {
            givenName:  'John',
            familyName: 'Smith'
          },
          privateName: {
            givenName:  'Alt John',
            familyName: 'Alt Smith'
          }
        )

        result = resource.as_json

        expect(result['schemas']             ).to eql(['custom-id'])
        expect(result['meta']['resourceType']).to eql('CustomResourse')
        expect(result['errors']              ).to be_nil
        expect(result['name']                ).to be_present
        expect(result['name']['givenName']   ).to eql('John')
        expect(result['name']['familyName']  ).to eql('Smith')
        expect(result['privateName']         ).to be_present
      end
    end # "context '#as_json' do"

    context '.find_attribute' do
      shared_examples 'a finder' do | force_upper_case: |
        it 'which finds in complex type' do
          args = ['name', 'givenName']
          args.map!(&:upcase) if force_upper_case

          found = CustomResourse.find_attribute(*args)

          expect(found).to be_present
          expect(found.name).to eql('givenName')
          expect(found.type).to eql('string')
        end

        it 'which finds in multi-value type, without index' do
          args = ['names', 'givenName']
          args.map!(&:upcase) if force_upper_case

          found = CustomResourse.find_attribute(*args)

          expect(found).to be_present
          expect(found.name).to eql('givenName')
          expect(found.type).to eql('string')
        end

        it 'which finds in multi-value type, ignoring index' do
          args = if force_upper_case
            ['NAMES', 42, 'GIVENNAME']
          else
            ['names', 42, 'givenName']
          end

          found = CustomResourse.find_attribute(*args)

          expect(found).to be_present
          expect(found.name).to eql('givenName')
          expect(found.type).to eql('string')
        end # "shared_examples 'a finder' do | force_upper_case: |"
      end

      context 'using schema-matched case' do
        it_behaves_like 'a finder', force_upper_case: false
      end # "context 'using schema-matched case' do"

      context 'using upper case' do
        it_behaves_like 'a finder', force_upper_case: true
      end # "context 'using upper case' do"
    end # "context '.find_attribute' do"
  end # "context 'basic operation' do"

  context 'dynamic setters based on schema' do
    SecondCustomSchema = Class.new(Scimitar::Schema::Base) do
      def self.scim_attributes
        [
          Scimitar::Schema::Attribute.new(name: 'customField', type: 'string', required: false),
          Scimitar::Schema::Attribute.new(name: 'anotherCustomField', type: 'boolean', required: false),
          Scimitar::Schema::Attribute.new(name: 'name', complexType: Scimitar::ComplexTypes::Name, required: false)
        ]
      end
    end

    CustomNameType = Class.new(Scimitar::ComplexTypes::Base) do
      set_schema Scimitar::Schema::Name
    end

    it 'defines a setter for an attribute in the schema' do
      described_class.set_schema SecondCustomSchema
      resource = described_class.new(customField: '100',
                                     anotherCustomField: true)
      expect(resource.customField).to eql('100')
      expect(resource.anotherCustomField).to eql(true)
      expect(resource.valid?).to be(true)
    end

    it 'defines a setter for an attribute in the schema' do
      described_class.set_schema SecondCustomSchema
      resource = described_class.new(anotherCustomField: false)
      expect(resource.anotherCustomField).to eql(false)
      expect(resource.valid?).to be(true)
    end

    it 'validates that the provided attributes match their schema' do
      described_class.set_schema SecondCustomSchema
      resource = described_class.new(
        name: Scimitar::ComplexTypes::Name.new(
          givenName: 'John',
          familyName: 'Smith'
        ))
      expect(resource.valid?).to be(true)
    end

    it 'validates that nested types' do
      described_class.set_schema SecondCustomSchema
      resource = described_class.new(
        name: Scimitar::ComplexTypes::Name.new(
          givenName: 100,
          familyName: 'Smith'
        ))
      expect(resource.valid?).to be(false)
    end

    it 'allows custom complex types as long as the schema matches' do
      described_class.set_schema SecondCustomSchema
      resource = described_class.new(
        name: CustomNameType.new(
          givenName: 'John',
          familyName: 'Smith'
        ))
      expect(resource.valid?).to be(true)
    end

    it 'doesn\'t accept email for a name' do
      described_class.set_schema SecondCustomSchema
      resource = described_class.new(
        name: Scimitar::ComplexTypes::Email.new(
          value: 'john@smith.com',
          primary: true
        ))
      expect(resource.valid?).to be(false)
    end

    it 'doesn\'t accept a complex type for a string' do
      described_class.set_schema SecondCustomSchema
      resource = described_class.new(
        customField: Scimitar::ComplexTypes::Email.new(
          value: 'john@smith.com',
          primary: true
        ))
      expect(resource.valid?).to be(false)
    end

    it 'doesn\'t accept a string for a boolean' do
      described_class.set_schema SecondCustomSchema
      resource = described_class.new(anotherCustomField: 'value')
      expect(resource.valid?).to be(false)
    end
  end # "context 'dynamic setters based on schema' do"

  context 'schema extension' do
    context 'of custom schema' do
      ThirdCustomSchema = Class.new(Scimitar::Schema::Base) do
        def self.id
          'custom-id'
        end

        def self.scim_attributes
          [ Scimitar::Schema::Attribute.new(name: 'name', type: 'string') ]
        end
      end

      ExtensionSchema = Class.new(Scimitar::Schema::Base) do
        def self.id
          'extension-id'
        end

        def self.scim_attributes
          [
            Scimitar::Schema::Attribute.new(name: 'relationship', type: 'string', required: true),
            Scimitar::Schema::Attribute.new(name: "userGroups", multiValued: true, complexType: Scimitar::ComplexTypes::ReferenceGroup, mutability: "writeOnly")
          ]
        end
      end

      let(:resource_class) {
        Class.new(Scimitar::Resources::Base) do
          set_schema ThirdCustomSchema
          extend_schema ExtensionSchema

          def self.endpoint
            '/gaga'
          end

          def self.resource_type_id
            'CustomResource'
          end
        end
      }

      context '#initialize' do
        it 'allows setting extension attributes' do
          resource = resource_class.new('extension-id' => {relationship: 'GAGA'})
          expect(resource.relationship).to eql('GAGA')
        end

        it 'allows setting complex extension attributes' do
          user_groups = [{ value: '123' }, { value: '456'}]
          resource = resource_class.new('extension-id' => {userGroups: user_groups})
          expect(resource.userGroups.map(&:value)).to eql(['123', '456'])
        end
      end # "context '#initialize' do"

      context '#as_json' do
        it 'namespaces the extension attributes' do
          resource = resource_class.new(relationship: 'GAGA')
          hash = resource.as_json
          expect(hash["schemas"]).to eql(['custom-id', 'extension-id'])
          expect(hash["extension-id"]).to eql("relationship" => 'GAGA')
        end
      end # "context '#as_json' do"

      context '.resource_type' do
        it 'appends the extension schemas' do
          resource_type = resource_class.resource_type('http://gaga')
          expect(resource_type.meta.location).to eql('http://gaga')
          expect(resource_type.schemaExtensions.count).to eql(1)
        end

        context 'validation' do
          it 'validates into custom schema' do
            resource = resource_class.new('extension-id' => {})
            expect(resource.valid?).to eql(false)

            resource = resource_class.new('extension-id' => {relationship: 'GAGA'})
            expect(resource.relationship).to eql('GAGA')
            expect(resource.valid?).to eql(true)
          end
        end # context 'validation'
      end # "context '.resource_type' do"

      context '.find_attribute' do
        it 'finds in first schema' do
          found = resource_class().find_attribute('name') # Defined in ThirdCustomSchema
          expect(found).to be_present
          expect(found.name).to eql('name')
          expect(found.type).to eql('string')
        end

        it 'finds across schemas' do
          found = resource_class().find_attribute('relationship') # Defined in ExtensionSchema
          expect(found).to be_present
          expect(found.name).to eql('relationship')
          expect(found.type).to eql('string')
        end
      end # "context '.find_attribute' do"
    end # "context 'of custom schema' do"

    context 'of core schema' do
      EnterpriseExtensionSchema = Class.new(Scimitar::Schema::Base) do
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

      let(:resource_class) {
        Class.new(Scimitar::Resources::Base) do
          set_schema Scimitar::Schema::User
          extend_schema EnterpriseExtensionSchema

          def self.endpoint
            '/Users'
          end

          def self.resource_type_id
            'User'
          end
        end
      }

      context '#initialize' do
        it 'allows setting extension attributes' do
          resource = resource_class.new('urn:ietf:params:scim:schemas:extension:enterprise:2.0:User' => {organization: 'SOMEORG', department: 'SOMEDPT'})

          expect(resource.organization).to eql('SOMEORG')
          expect(resource.department  ).to eql('SOMEDPT')
        end
      end # "context '#initialize' do"

      context '#as_json' do
        it 'namespaces the extension attributes' do
          resource = resource_class.new(organization: 'SOMEORG', department: 'SOMEDPT')
          hash = resource.as_json

          expect(hash['schemas']).to eql(['urn:ietf:params:scim:schemas:core:2.0:User', 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User'])
          expect(hash['urn:ietf:params:scim:schemas:extension:enterprise:2.0:User']).to eql('organization' => 'SOMEORG', 'department' => 'SOMEDPT')
        end
      end # "context '#as_json' do"

      context '.resource_type' do
        it 'appends the extension schemas' do
          resource_type = resource_class.resource_type('http://example.com')
          expect(resource_type.meta.location).to eql('http://example.com')
          expect(resource_type.schemaExtensions.count).to eql(1)
        end

        context 'validation' do
          it 'validates into custom schema' do
            resource = resource_class.new('urn:ietf:params:scim:schemas:extension:enterprise:2.0:User' => {})
            expect(resource.valid?).to eql(false)

            resource = resource_class.new(
              'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User' => {
                userName:     'SOMEUSR',
                organization: 'SOMEORG',
                department:   'SOMEDPT'
              }
            )

            expect(resource.organization).to eql('SOMEORG')
            expect(resource.department  ).to eql('SOMEDPT')
            expect(resource.valid?      ).to eql(true)
          end
        end # context 'validation'
      end # "context '.resource_type' do"

      context '.find_attribute' do
        it 'finds in first schema' do
          found = resource_class().find_attribute('userName') # Defined in Scimitar::Schema::User

          expect(found).to be_present
          expect(found.name).to eql('userName')
          expect(found.type).to eql('string')
        end

        it 'finds across schemas' do
          found = resource_class().find_attribute('organization') # Defined in EnterpriseExtensionSchema
          expect(found).to be_present
          expect(found.name).to eql('organization')
          expect(found.type).to eql('string')
        end
      end # "context '.find_attribute' do"
    end # "context 'of core schema' do"
  end # "context 'schema extension' do"
end
