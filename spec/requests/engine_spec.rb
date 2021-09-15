require 'spec_helper'

RSpec.describe Scimitar::Engine do
  before :each do
    allow_any_instance_of(Scimitar::ApplicationController).to receive(:authenticated?).and_return(true)
  end

  context 'parameter parser' do

    # "params" given here as a String, expecting the engine's custom parser to
    # decode it for us.
    #
    it 'decodes simple JSON', type: :model do
      post '/Users.scim', params: '{"userName": "foo"}', headers: { 'CONTENT_TYPE' => 'application/scim+json' }

      expect(response.status).to eql(201)
      expect(JSON.parse(response.body)['userName']).to eql('foo')
    end

    it 'decodes nested JSON', type: :model do
      post '/Users.scim', params: '{"userName": "foo", "name": {"givenName": "bar", "familyName": "baz"}}', headers: { 'CONTENT_TYPE' => 'application/scim+json' }

      expect(response.status).to eql(201)
      expect(JSON.parse(response.body)['userName']).to eql('foo')
      expect(JSON.parse(response.body)['name']['givenName']).to eql('bar')
      expect(JSON.parse(response.body)['name']['familyName']).to eql('baz')
    end

    it 'is case insensitive at the top level', type: :model do
      post '/Users.scim', params: '{"USERNAME": "foo"}', headers: { 'CONTENT_TYPE' => 'application/scim+json' }

      expect(response.status).to eql(201)
      expect(JSON.parse(response.body)['userName']).to eql('foo')
    end

    it 'is case insensitive in nested levels', type: :model do
      post '/Users.scim', params: '{"USERNAME": "foo", "NAME": {"GIVENNAME": "bar", "FAMILYNAME": "baz"}}', headers: { 'CONTENT_TYPE' => 'application/scim+json' }

      expect(response.status).to eql(201)
      expect(JSON.parse(response.body)['userName']).to eql('foo')
      expect(JSON.parse(response.body)['name']['givenName']).to eql('bar')
      expect(JSON.parse(response.body)['name']['familyName']).to eql('baz')
    end
  end # "context 'parameter parser' do"
end
