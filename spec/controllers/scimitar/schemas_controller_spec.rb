require 'spec_helper'

RSpec.describe Scimitar::SchemasController do
  routes { Scimitar::Engine.routes }

  before(:each) { allow(controller).to receive(:authenticated?).and_return(true) }

  controller do
    def index
      super
    end
  end

  context '#index' do
    shared_examples 'a Schema list which' do
      it 'returns a valid ListResponse' do
        get :index, params: { format: :scim }
        expect(response).to be_ok

        parsed_body  = JSON.parse(response.body)
        schema_count = parsed_body['Resources']&.size

        expect(parsed_body['schemas'     ]).to match_array(['urn:ietf:params:scim:api:messages:2.0:ListResponse'])
        expect(parsed_body['totalResults']).to eql(schema_count)
        expect(parsed_body['itemsPerPage']).to eql(schema_count)
        expect(parsed_body['startIndex'  ]).to eql(1)
      end

      it 'returns a collection of supported schemas' do
        get :index, params: { format: :scim }
        expect(response).to be_ok

        parsed_body = JSON.parse(response.body)
        expect(parsed_body['Resources']&.size).to eql(4)

        schema_names = parsed_body['Resources'].map {|schema| schema['name']}
        expect(schema_names).to match_array(['User', 'EnterpriseExtendedUser', 'ManagementExtendedUser', 'Group'])
      end

      it 'returns only the User schema when its ID is provided' do
        get :index, params: { name: Scimitar::Schema::User.id, format: :scim }
        expect(response).to be_ok

        parsed_body = JSON.parse(response.body)
        expect(parsed_body.dig('Resources', 0, 'name')).to eql('User')
      end

      it 'includes the controller customised schema location' do
        get :index, params: { name: Scimitar::Schema::User.id, format: :scim }
        expect(response).to be_ok

        parsed_body = JSON.parse(response.body)
        expect(parsed_body.dig('Resources', 0, 'meta', 'location')).to eq scim_schemas_url(name: Scimitar::Schema::User.id, test: 1)
      end

      it 'returns only the Group schema when its ID is provided' do
        get :index, params: { name: Scimitar::Schema::Group.id, format: :scim }
        expect(response).to be_ok

        parsed_body = JSON.parse(response.body)

        expect(parsed_body['Resources'   ]&.size).to eql(1)
        expect(parsed_body['totalResults']      ).to eql(1)
        expect(parsed_body['itemsPerPage']      ).to eql(1)
        expect(parsed_body['startIndex'  ]      ).to eql(1)

        expect(parsed_body.dig('Resources', 0, 'name')).to eql('Group')
      end
    end

    context 'with default engine configuration of schema_list_from_attribute_mappings undefined' do
      it_behaves_like 'a Schema list which'

      it 'returns all attributes' do
        get :index, params: { name: Scimitar::Schema::User.id, format: :scim }
        expect(response).to be_ok

        parsed_body = JSON.parse(response.body)
        user_attrs  = parsed_body['Resources'].find { | r | r['name'] == 'User' }

        expect(user_attrs['attributes'].find { | a | a['name'] == 'ims'              }).to be_present
        expect(user_attrs['attributes'].find { | a | a['name'] == 'entitlements'     }).to be_present
        expect(user_attrs['attributes'].find { | a | a['name'] == 'x509Certificates' }).to be_present

        name_attr = user_attrs['attributes'].find { | a | a['name'] == 'name' }

        expect(name_attr['subAttributes'].find { | s | s['name'] == 'honorificPrefix' }).to be_present
        expect(name_attr['subAttributes'].find { | s | s['name'] == 'honorificSuffix' }).to be_present
      end

      context 'with custom resource types' do
        around :each do | example |
          example.run()
        ensure
          Scimitar::Engine.reset_custom_resources
        end

        it 'returns only the License schemas when its ID is provided' do
          license_schema = Class.new(Scimitar::Schema::Base) do
            def initialize(options = {})
              super(name: 'License', id: self.class.id(), description: 'Represents a License')
            end
            def self.id; 'urn:ietf:params:scim:schemas:license'; end
            def self.scim_attributes; []; end
          end

          license_resource = Class.new(Scimitar::Resources::Base) do
            set_schema(license_schema)
            def self.endpoint; '/License'; end
          end

          Scimitar::Engine.add_custom_resource(license_resource)

          get :index, params: { name: license_schema.id, format: :scim }
          expect(response).to be_ok

          parsed_body = JSON.parse(response.body)
          expect(parsed_body.dig('Resources', 0, 'name')).to eql('License')
        end
      end # "context 'with custom resource types' do"
    end # "context 'with default engine configuration of schema_list_from_attribute_mappings undefined' do"

    context 'with engine configuration of schema_list_from_attribute_mappings set' do
      context 'standard resources' do
        around :each do | example |
          old_config = Scimitar.engine_configuration.schema_list_from_attribute_mappings
          Scimitar.engine_configuration.schema_list_from_attribute_mappings = [
            MockUser,
            MockGroup
          ]
          example.run()
        ensure
          Scimitar.engine_configuration.schema_list_from_attribute_mappings = old_config
        end

        it_behaves_like 'a Schema list which'

        it 'returns only mapped attributes' do
          get :index, params: { name: Scimitar::Schema::User.id, format: :scim }
          expect(response).to be_ok

          parsed_body   = JSON.parse(response.body)
          user_attrs    = parsed_body['Resources'].find { | r | r['name'] == 'User'     }
          password_attr = user_attrs['attributes'].find { | a | a['name'] == 'password' }

          expect(password_attr['mutability']).to eql('writeOnly')

          expect(user_attrs['attributes'].find { | a | a['name'] == 'ims'              }).to_not be_present
          expect(user_attrs['attributes'].find { | a | a['name'] == 'entitlements'     }).to_not be_present
          expect(user_attrs['attributes'].find { | a | a['name'] == 'x509Certificates' }).to_not be_present

          name_attr = user_attrs['attributes'].find { | a | a['name'] == 'name' }

          expect(name_attr['subAttributes'].find { | s | s['name'] == 'givenName'       }).to     be_present
          expect(name_attr['subAttributes'].find { | s | s['name'] == 'familyName'      }).to     be_present
          expect(name_attr['subAttributes'].find { | s | s['name'] == 'honorificPrefix' }).to_not be_present
          expect(name_attr['subAttributes'].find { | s | s['name'] == 'honorificSuffix' }).to_not be_present

          emails_attr  =  user_attrs['attributes'   ].find { | a | a['name'] == 'emails'  }
          value_attr   = emails_attr['subAttributes'].find { | a | a['name'] == 'value'   }
          primary_attr = emails_attr['subAttributes'].find { | a | a['name'] == 'primary' }

          expect(  value_attr['mutability']).to eql('readWrite')
          expect(primary_attr['mutability']).to eql('readOnly')

          expect(emails_attr['subAttributes'].find { | s | s['name'] == 'type'    }).to_not be_present
          expect(emails_attr['subAttributes'].find { | s | s['name'] == 'display' }).to_not be_present

          groups_attr  =  user_attrs['attributes'   ].find { | a | a['name'] == 'groups'  }
          value_attr   = groups_attr['subAttributes'].find { | a | a['name'] == 'value'   }
          display_attr = groups_attr['subAttributes'].find { | a | a['name'] == 'display' }

          expect(  value_attr['mutability']).to eql('readOnly')
          expect(display_attr['mutability']).to eql('readOnly')
        end
      end

      context 'with custom resource types' do
        let(:license_schema) {
          Class.new(Scimitar::Schema::Base) do
            def initialize(options = {})
              super(
                id:              self.class.id(),
                name:            'License',
                description:     'Represents a license',
                scim_attributes: self.class.scim_attributes
              )
            end
            def self.id; 'urn:ietf:params:scim:schemas:license'; end
            def self.scim_attributes
              [
                Scimitar::Schema::Attribute.new(name: 'licenseNumber',  type: 'string'),
                Scimitar::Schema::Attribute.new(name: 'licenseExpired', type: 'boolean', mutability: 'readOnly'),
              ]
            end
          end
        }

        let(:license_resource) {
          local_var_license_schema = license_schema()

          Class.new(Scimitar::Resources::Base) do
            set_schema(local_var_license_schema)
            def self.endpoint; '/License'; end
          end
        }

        let(:license_model_base) {
          local_var_license_resource = license_resource()

          Class.new do
            singleton_class.class_eval do
              define_method(:scim_resource_type) { local_var_license_resource }
            end
          end
        }

        around :each do | example |
          old_config = Scimitar.engine_configuration.schema_list_from_attribute_mappings
          Scimitar::Engine.add_custom_resource(license_resource())
          example.run()
        ensure
          Scimitar.engine_configuration.schema_list_from_attribute_mappings = old_config
          Scimitar::Engine.reset_custom_resources
        end

        context 'with an empty attribute map' do
          it 'returns no attributes' do
            license_model = Class.new(license_model_base()) do
              attr_accessor :license_number

              def self.scim_mutable_attributes; nil; end
              def self.scim_queryable_attributes; nil; end
              def self.scim_attributes_map; {}; end # Empty map

              include Scimitar::Resources::Mixin
            end

            Scimitar.engine_configuration.schema_list_from_attribute_mappings = [license_model]

            get :index, params: { format: :scim }
            expect(response).to be_ok

            parsed_body = JSON.parse(response.body)

            expect(parsed_body.dig('Resources', 0, 'name'      )).to eql('License')
            expect(parsed_body.dig('Resources', 0, 'attributes')).to be_empty
          end
        end # "context 'with an empty attribute map' do"

        context 'with a defined attribute map' do
          it 'returns only the License schemas when its ID is provided' do
            license_model = Class.new(license_model_base()) do
              attr_accessor :license_number

              def self.scim_mutable_attributes; nil; end
              def self.scim_queryable_attributes; nil; end
              def self.scim_attributes_map # Simple map
                { licenseNumber: :license_number }
              end

              include Scimitar::Resources::Mixin
            end

            Scimitar.engine_configuration.schema_list_from_attribute_mappings = [license_model]

            get :index, params: { format: :scim }
            expect(response).to be_ok

            parsed_body = JSON.parse(response.body)

            expect(parsed_body.dig('Resources', 0, 'name'                       )).to eql('License')
            expect(parsed_body.dig('Resources', 0, 'attributes').size            ).to eql(1)
            expect(parsed_body.dig('Resources', 0, 'attributes', 0, 'name'      )).to eql('licenseNumber')
            expect(parsed_body.dig('Resources', 0, 'attributes', 0, 'mutability')).to eql('readWrite')
          end
        end # "context 'with a defined attribute map' do"

        context 'with mutability overridden' do
          it 'returns read-only when expected' do
            license_model = Class.new(license_model_base()) do
              attr_accessor :license_number

              def self.scim_mutable_attributes; []; end # Note empty array, NOT "nil" - no mutable attributes
              def self.scim_queryable_attributes; nil; end
              def self.scim_attributes_map
                { licenseNumber: :license_number }
              end

              include Scimitar::Resources::Mixin
            end

            Scimitar.engine_configuration.schema_list_from_attribute_mappings = [license_model]

            get :index, params: { format: :scim }
            expect(response).to be_ok

            parsed_body = JSON.parse(response.body)

            expect(parsed_body.dig('Resources', 0, 'name'                       )).to eql('License')
            expect(parsed_body.dig('Resources', 0, 'attributes').size            ).to eql(1)
            expect(parsed_body.dig('Resources', 0, 'attributes', 0, 'name'      )).to eql('licenseNumber')
            expect(parsed_body.dig('Resources', 0, 'attributes', 0, 'mutability')).to eql('readOnly')
          end

          it 'returns write-only when expected' do
            license_model = Class.new(license_model_base()) do
              attr_writer :license_number # Writer only, no reader

              def self.scim_mutable_attributes; nil; end
              def self.scim_queryable_attributes; nil; end
              def self.scim_attributes_map
                { licenseNumber: :license_number }
              end

              include Scimitar::Resources::Mixin
            end

            Scimitar.engine_configuration.schema_list_from_attribute_mappings = [license_model]

            get :index, params: { format: :scim }
            expect(response).to be_ok

            parsed_body = JSON.parse(response.body)

            expect(parsed_body.dig('Resources', 0, 'name'                       )).to eql('License')
            expect(parsed_body.dig('Resources', 0, 'attributes').size            ).to eql(1)
            expect(parsed_body.dig('Resources', 0, 'attributes', 0, 'name'      )).to eql('licenseNumber')
            expect(parsed_body.dig('Resources', 0, 'attributes', 0, 'mutability')).to eql('writeOnly')
          end

          it 'handles conflicts via reality-wins' do
            license_model = Class.new(license_model_base()) do
              def self.scim_mutable_attributes; [:licence_expired]; end
              def self.scim_queryable_attributes; nil; end
              def self.scim_attributes_map
                { licenseNumber: :license_number, licenseExpired: :licence_expired }
              end

              include Scimitar::Resources::Mixin
            end

            Scimitar.engine_configuration.schema_list_from_attribute_mappings = [license_model]

            get :index, params: { format: :scim }
            expect(response).to be_ok

            parsed_body = JSON.parse(response.body)
            attributes  = parsed_body.dig('Resources', 0, 'attributes')

            expect(parsed_body.dig('Resources', 0, 'name')).to eql('License')
            expect(attributes.size).to eql(2)

            number_attr = attributes.find { | a | a['name'] == 'licenseNumber'  }
            expiry_attr = attributes.find { | a | a['name'] == 'licenseExpired' }

            # Number attribute - no reader or writer, so code has to shrug and
            # say "it's broken, so I'll quote the schema verbatim'.
            #
            # Expiry attribute - is read-only in schema, but we declare it as a
            # writable attribute and provide no reader. This clashes badly; the
            # schema read-only declaration is ignored in favour of reality.
            #
            expect(number_attr['mutability']).to eql('readWrite')
            expect(expiry_attr['mutability']).to eql('writeOnly')
          end
        end # "context 'with mutability overridden' do"
      end # "context 'with custom resource types' do"
    end # "context 'with engine configuration of schema_list_from_attribute_mappings: true' do"
  end # "context '#index' do
end
