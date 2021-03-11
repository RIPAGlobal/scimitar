require 'spec_helper'

RSpec.describe Scimitar::ResourcesController do
  class FakeGroup
    include ActiveModel::Model

    attr_accessor :scim_id
    attr_accessor :display_name
    attr_accessor :member_names

    def self.scim_resource_type
      return Scimitar::Resources::Group
    end

    def self.scim_attributes_map
      return {
        id:          :id,
        externalId:  :scim_id,
        displayName: :display_name,
        members:     :member_names
      }
    end

    def self.scim_mutable_attributes
      return nil
    end

    def self.scim_queryable_attributes
      return { displayName: display_name }
    end

    include Scimitar::Resources::Mixin
  end

  let(:response_body) { JSON.parse(response.body, symbolize_names: true) }

  before(:each) do
    allow(controller).to receive(:authenticated?).and_return(true)
    allow(FakeGroup ).to receive(:all).and_return(double('ActiveRecord::Relation', where: []))
  end

  controller do
    def index
      super(FakeGroup.all) do | fake_group |
        fake_group
      end
    end

    def show
      super do |id|
        Scimitar::Resources::Group.new(id: id)
      end
    end

    def create
      super do |resource|
        resource
      end
    end

    def update
      super do |resource|
        resource
      end
    end

    def destroy
      super do |id|
        successful_delete?
      end
    end

    def successful_delete? # Just a test hook
      true
    end

    protected

      def storage_class
        FakeGroup
      end
  end

  context 'GET show' do
    it 'renders the resource' do
      get :show, params: { id: '10', format: :scim }

      expect(response).to be_ok
      expect(response_body).to include(id: '10')
    end
  end

  context 'POST create' do
    it 'returns error if body is missing' do
      post :create, params: { format: :scim }
      expect(response.status).to eql(400)
      expect(response_body[:detail]).to eql('must provide a request body')
    end

    it 'works if the request is valid' do
      post :create, params: { displayName: 'Sauron biz', format: :scim }
      expect(response).to have_http_status(:created)
      expect(response_body[:displayName]).to eql('Sauron biz')
    end

    it 'renders error if resource object cannot be built from the params' do
      put :replace, params: { id: 'group-id', name: {email: 'a@b.com'}, format: :scim }
      expect(response.status).to eql(400)
      expect(response_body[:detail]).to match(/^Invalid/)
    end

    it 'renders application side error' do
      allow_any_instance_of(Scimitar::Resources::Group).to receive(:to_json).and_raise(Scimitar::ErrorResponse.new(status: 400, detail: 'gaga'))
      put :replace, params: { id: 'group-id', displayName: 'invalid name', format: :scim }
      expect(response.status).to eql(400)
      expect(response_body[:detail]).to eql('gaga')
    end

    it 'renders error if id is provided' do
      post :create, params: { id: 'some-id', displayName: 'sauron', format: :scim }

      expect(response).to have_http_status(:bad_request)
      expect(response_body[:detail]).to start_with('"id" is not a valid parameter for POST')
    end

    it 'does not renders error if externalId is provided' do
      post :create, params: { externalId: 'some-id', displayName: 'sauron', format: :scim }

      expect(response).to have_http_status(:created)

      expect(response_body[:displayName]).to eql('sauron')
      expect(response_body[:externalId]).to eql('some-id')
    end
  end

  context 'PUT update' do
    it 'returns error if body is missing' do
      put :replace, params: { id: 'group-id', format: :scim }
      expect(response.status).to eql(400)
      expect(response_body[:detail]).to eql('must provide a request body')
    end

    it 'works if the request is valid' do
      put :replace, params: { id: 'group-id', displayName: 'sauron', format: :scim }
      expect(response.status).to eql(200)
      expect(response_body[:displayName]).to eql('sauron')
    end

    it 'renders error if resource object cannot be built from the params' do
      put :replace, params: { id: 'group-id', name: {email: 'a@b.com'}, format: :scim }
      expect(response.status).to eql(400)
      expect(response_body[:detail]).to match(/^Invalid/)
    end

    it 'renders application side error' do
      allow_any_instance_of(Scimitar::Resources::Group).to receive(:to_json).and_raise(Scimitar::ErrorResponse.new(status: 400, detail: 'gaga'))
      put :replace, params: { id: 'group-id', displayName: 'invalid name', format: :scim }
      expect(response.status).to eql(400)
      expect(response_body[:detail]).to eql('gaga')
    end

  end

  context 'DELETE destroy' do
    it 'returns an empty response with no content status if deletion is successful' do
      delete :destroy, params: { id: 'group-id', format: :scim }
      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end

    it 'renders error if deletion fails' do
      allow(controller).to receive(:successful_delete?).and_return(false)
      delete :destroy, params: { id: 'group-id', format: :scim }
      expect(response).to have_http_status(:internal_server_error)
      expect(response_body[:detail]).to eql("Failed to delete the resource with id 'group-id'. Please try again later.")
    end
  end
end
