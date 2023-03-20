# Some tests require the more flexible driver methods for 'get', 'post'
# etc. than available in RSpec controller tests.
#
# See also spec/controllers/scimitar/application_controller_spec.rb.
#
require 'spec_helper'

RSpec.describe Scimitar::ApplicationController do
  before :each do
    allow_any_instance_of(Scimitar::ApplicationController).to receive(:authenticated?).and_return(true)
  end

  context 'format handling' do
    it 'renders "OK" if the request does not provide any Content-Type value' do
      get '/CustomRequestVerifiers', params: { format: :html }

      expect(response).to have_http_status(:ok)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['request']['is_scim'     ]).to eql(true)
      expect(parsed_body['request']['format'      ]).to eql('application/scim+json')
      expect(parsed_body['request']['content_type']).to eql('application/scim+json')
    end

    it 'renders 400 if given bad JSON' do
      post '/CustomRequestVerifiers', params: 'not-json-12345', headers: { 'CONTENT_TYPE' => 'application/scim+json' }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['detail']).to start_with('Invalid JSON - ')
      expect(JSON.parse(response.body)['detail']).to include("'not-json-12345'")
    end

    it 'translates Content-Type to Rails request format' do
      get '/CustomRequestVerifiers', headers: { 'CONTENT_TYPE' => 'application/scim+json' }

      expect(response).to have_http_status(:ok)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['request']['is_scim'     ]).to eql(true)
      expect(parsed_body['request']['format'      ]).to eql('application/scim+json')
      expect(parsed_body['request']['content_type']).to eql('application/scim+json')
    end

    it 'translates Content-Type with charset to Rails request format' do
      get '/CustomRequestVerifiers', headers: { 'CONTENT_TYPE' => 'application/scim+json; charset=utf-8' }

      expect(response).to have_http_status(:ok)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['request']['is_scim'     ]).to eql(true)
      expect(parsed_body['request']['format'      ]).to eql('application/scim+json')
      expect(parsed_body['request']['content_type']).to eql('application/scim+json; charset=utf-8')
    end

    it 'translates Rails request format to header' do
      get '/CustomRequestVerifiers', params: { format: :scim }

      expect(response).to have_http_status(:ok)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['request']['is_scim'     ]).to eql(true)
      expect(parsed_body['request']['format'      ]).to eql('application/scim+json')
      expect(parsed_body['request']['content_type']).to eql('application/scim+json')
    end
  end
end
