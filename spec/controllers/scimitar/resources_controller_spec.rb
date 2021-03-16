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

  let(:parsed_response) { JSON.parse(response.body, symbolize_names: true) }

  before(:each) do
    allow(controller()).to receive(:authenticated?).and_return(true)
    allow(FakeGroup   ).to receive(:all).and_return(double('ActiveRecord::Relation', where: []))
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

    def replace
      super do |record_id, resource|
        resource
      end
    end

    # PATCH is more easily (and comprehensively) tested via
    # spec/requests/active_record_backed_resources_controller_spec.rb.
    #
    def update # PATCH
      raise NotImplementedError
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
      expect(response.status).to eql(200)
      expect(parsed_response()).to include(id: '10')
    end
  end

  context 'POST create' do
    it 'returns error if body is missing' do
      post :create, params: { format: :scim }
      expect(response.status).to eql(400)
      expect(parsed_response()[:detail]).to eql('must provide a request body')
    end

    it 'works if the request is valid' do
      post :create, params: { displayName: 'Sauron biz', format: :scim }
      expect(response).to have_http_status(:created)
      expect(parsed_response()[:displayName]).to eql('Sauron biz')
    end

    it 'renders error if resource object cannot be built from the params' do
      @routes.draw do
        put 'scimitar/resources/:id', action: 'replace', controller: 'scimitar/resources'
      end
      put :replace, params: { id: 'group-id', name: {email: 'a@b.com'}, format: :scim }

      expect(response.status).to eql(400)
      expect(parsed_response()[:detail]).to match(/^Invalid/)
    end

    it 'renders application side error' do
      expect_any_instance_of(Scimitar::Resources::Group).to receive(:to_json).and_raise(Scimitar::ErrorResponse.new(status: 400, detail: 'gaga'))

      @routes.draw do
        put 'scimitar/resources/:id', action: 'replace', controller: 'scimitar/resources'
      end
      put :replace, params: { id: 'group-id', displayName: 'invalid name', format: :scim }

      expect(response.status).to eql(400)
      expect(parsed_response()[:detail]).to eql('gaga')
    end

    it 'renders externalId if provided' do
      post :create, params: { externalId: 'some-id', displayName: 'sauron', format: :scim }

      expect(response).to have_http_status(:created)

      expect(parsed_response()[:displayName]).to eql('sauron')
      expect(parsed_response()[:externalId]).to eql('some-id')
    end

    it 'maps internal NoMethodError failures to "Invalid request"' do
      expect(controller()).to receive(:validate_request) { raise NoMethodError.new }

      post :create, params: { externalId: 'some-id', displayName: 'sauron', format: :scim }

      expect(response.status).to eql(400)
      expect(parsed_response()[:detail]).to eql('Invalid request')
    end
  end

  context 'PUT update' do
    it 'returns error if body is missing' do
      @routes.draw do
        put 'scimitar/resources/:id', action: 'replace', controller: 'scimitar/resources'
      end
      put :replace, params: { id: 'group-id', format: :scim }

      expect(response.status).to eql(400)
      expect(parsed_response()[:detail]).to eql('must provide a request body')
    end

    it 'works if the request is valid' do
      @routes.draw do
        put 'scimitar/resources/:id', action: 'replace', controller: 'scimitar/resources'
      end
      put :replace, params: { id: 'group-id', displayName: 'sauron', format: :scim }

      expect(response.status).to eql(200)
      expect(parsed_response()[:displayName]).to eql('sauron')
    end

    it 'renders error if resource object cannot be built from the params' do
      @routes.draw do
        put 'scimitar/resources/:id', action: 'replace', controller: 'scimitar/resources'
      end
      put :replace, params: { id: 'group-id', name: {email: 'a@b.com'}, format: :scim }

      expect(response.status).to eql(400)
      expect(parsed_response()[:detail]).to match(/^Invalid/)
    end

    it 'renders application side error' do
      allow_any_instance_of(Scimitar::Resources::Group).to receive(:to_json).and_raise(Scimitar::ErrorResponse.new(status: 400, detail: 'gaga'))

      @routes.draw do
        put 'scimitar/resources/:id', action: 'replace', controller: 'scimitar/resources'
      end
      put :replace, params: { id: 'group-id', displayName: 'invalid name', format: :scim }

      expect(response.status).to eql(400)
      expect(parsed_response()[:detail]).to eql('gaga')
    end

  end

  context 'DELETE destroy' do
    it 'returns an empty response with no content status if deletion is successful' do
      delete :destroy, params: { id: 'group-id', format: :scim }
      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end

    it 'renders error if deletion fails' do
      allow(controller()).to receive(:successful_delete?).and_return(false)
      delete :destroy, params: { id: 'group-id', format: :scim }
      expect(response).to have_http_status(:internal_server_error)
      expect(parsed_response()[:detail]).to eql("Failed to delete the resource with id 'group-id'. Please try again later.")
    end
  end

  context 'service methods' do
    context '#scim_pagination_info' do
      it 'applies defaults' do
        result = controller().send(:scim_pagination_info)

        expect(result.limit).to eql(Scimitar.service_provider_configuration(location: nil).filter.maxResults)
        expect(result.offset).to eql(0)
        expect(result.start_index).to eql(1)
        expect(result.total).to be_nil
      end

      it 'reads parameters' do
        allow(controller()).to receive(:params).and_return({count: '10', startIndex: '5'})

        result = controller().send(:scim_pagination_info)

        expect(result.limit).to eql(10)
        expect(result.offset).to eql(4)
        expect(result.start_index).to eql(5)
      end

      it 'accepts an up-front total' do
        result = controller().send(:scim_pagination_info, 150)

        expect(result.total).to eql(150)
      end
    end # "context '#scim_pagination_info' do"

    context '#storage_class' do
      it 'raises "not implemented" to warn subclass authors' do
        expect { described_class.new.send(:storage_class) }.to raise_error(NotImplementedError)
      end
    end # "context '#storage_class' do"
  end # "context 'service methods' do"
end
