require 'spec_helper'

RSpec.describe Scimitar::Engine do
  before :each do
    allow_any_instance_of(Scimitar::ApplicationController).to receive(:authenticated?).and_return(true)
  end

  context 'parameter parser' do

    # "params" given here as a String, expecting the engine's custom parser to
    # decode it for us.
    #
    it 'decodes JSON', type: :model do
      post '/Users.scim', params: '{"userName": "foo"}', headers: { 'CONTENT_TYPE' => 'application/scim+json' }

      expect(response.status).to eql(201)
      expect(JSON.parse(response.body)['userName']).to eql('foo')
    end
  end # "context 'parameter parser' do"
end
