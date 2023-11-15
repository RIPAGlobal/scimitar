require 'spec_helper'

RSpec.describe Scimitar::ResourceTypesController do
  routes { Scimitar::Engine.routes }

  before(:each) { allow(controller).to receive(:authenticated?).and_return(true) }

  context 'GET index' do
    it 'renders the resource type for user' do
      get :index, format: :scim
      response_hash = JSON.parse(response.body)
      expected_response = [ Scimitar::Resources::User.resource_type(scim_resource_type_url(name: 'User', test: 1)),
                            Scimitar::Resources::Group.resource_type(scim_resource_type_url(name: 'Group', test: 1))
      ].to_json

      response_hash = JSON.parse(response.body)
      expect(response_hash).to eql(JSON.parse(expected_response))
    end

    context 'with custom resource types' do
      around :each do | example |
        example.run()
      ensure
        Scimitar::Engine.reset_custom_resources
      end

      it 'renders them' do
        custom_resource = Class.new(Scimitar::Resources::Base) do
          set_schema Scimitar::Schema::User

          def self.endpoint
            "/Gaga"
          end

          def self.resource_type_id
            'Gaga'
          end
        end

        Scimitar::Engine.add_custom_resource(custom_resource)

        get :index, params: { format: :scim }
        response_hash = JSON.parse(response.body)
        expect(response_hash.size).to eql(3)
      end
    end
  end

  context 'GET show' do
    it 'renders the resource type for user' do
      get :show, params: { name: 'User', format: :scim }
      response_hash = JSON.parse(response.body)
      expected_response = Scimitar::Resources::User.resource_type(scim_resource_type_url(name: 'User')).to_json
      expect(response_hash).to eql(JSON.parse(expected_response))
    end

    it 'renders the resource type for group' do
      get :show, params: { name: 'Group', format: :scim }
      response_hash = JSON.parse(response.body)
      expected_response = Scimitar::Resources::Group.resource_type(scim_resource_type_url(name: 'Group')).to_json
      expect(response_hash).to eql(JSON.parse(expected_response))
    end

    it 'renders custom resource type' do
      custom_resource = Class.new(Scimitar::Resources::Base) do
        set_schema Scimitar::Schema::User

        def self.endpoint
          "/Gaga"
        end

        def self.resource_type_id
          'Gaga'
        end
      end

      allow(Scimitar::Engine).to receive(:custom_resources) {[ custom_resource ]}

      get :show, params: { name: 'Gaga', format: :scim }
      response_hash = JSON.parse(response.body)
      expected_response = custom_resource.resource_type(scim_resource_type_url(name: 'Gaga')).to_json
      expect(response_hash).to eql(JSON.parse(expected_response))
    end

    it 'renders 404 if not recognised' do
      get :show, params: { name: 'Foo', format: :scim }
      expect(response).to have_http_status(:not_found)
      response_hash = JSON.parse(response.body)
      expect(response_hash['schemas']).to eql(['urn:ietf:params:scim:api:messages:2.0:Error'])
      expect(response_hash['status' ]).to eql('404')
      expect(response_hash['detail' ]).to eql('Resource "Foo" not found')
    end
  end
end
