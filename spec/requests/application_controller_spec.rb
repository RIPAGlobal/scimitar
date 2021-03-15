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
    it 'renders "not acceptable" if the request does not use SCIM type' do
      get '/CustomRequestVerifiers', params: { format: :html }

      expect(response).to have_http_status(:not_acceptable)
      expect(JSON.parse(response.body)['detail']).to eql('Only application/scim+json type is accepted.')
    end

    it 'translates Content-Type to Rails request format' do
      get '/CustomRequestVerifiers', headers: { 'CONTENT_TYPE' => 'application/scim+json' }

      expect(response).to have_http_status(:ok)
      parsed_body = JSON.parse(response.body)
      expect(parsed_body['request']['is_scim'     ]).to eql(true)
      expect(parsed_body['request']['format'      ]).to eql('application/scim+json')
      expect(parsed_body['request']['content_type']).to eql('application/scim+json')
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
