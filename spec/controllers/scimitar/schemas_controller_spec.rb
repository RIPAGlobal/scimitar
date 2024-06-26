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

    it 'returns only the User schema when its id is provided' do
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

    it 'returns only the Group schema when its id is provided' do
      get :index, params: { name: Scimitar::Schema::Group.id, format: :scim }
      expect(response).to be_ok

      parsed_body = JSON.parse(response.body)

      expect(parsed_body['Resources'   ]&.size).to eql(1)
      expect(parsed_body['totalResults']      ).to eql(1)
      expect(parsed_body['itemsPerPage']      ).to eql(1)
      expect(parsed_body['startIndex'  ]      ).to eql(1)

      expect(parsed_body.dig('Resources', 0, 'name')).to eql('Group')
    end

    context 'with custom resource types' do
      around :each do | example |
        example.run()
      ensure
        Scimitar::Engine.reset_custom_resources
      end

      it 'returns only the License schemas when its id is provided' do
        license_schema = Class.new(Scimitar::Schema::Base) do
          def initialize(options = {})
          super(name: 'License',
                id: self.class.id,
                description: 'Represents a License')
          end
          def self.id
            'License'
          end
          def self.scim_attributes
            []
          end
        end

        license_resource = Class.new(Scimitar::Resources::Base) do
          set_schema license_schema
          def self.endpoint
            '/Gaga'
          end
        end

        Scimitar::Engine.add_custom_resource(license_resource)

        get :index, params: { name: license_schema.id, format: :scim }
        expect(response).to be_ok
        parsed_body = JSON.parse(response.body)
        expect(parsed_body.dig('Resources', 0, 'name')).to eql('License')
      end
    end # "context 'with custom resource types' do"
  end # "context '#index' do
end

