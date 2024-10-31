require 'spec_helper'

RSpec.describe Scimitar::ServiceProviderConfigurationsController do

  before(:each) { allow(controller).to receive(:authenticated?).and_return(true) }

  controller do
    def show
      super
    end
  end
  context '#show' do
    it 'renders the servive provider configurations' do
      get :show, params: { id: 'fake', format: :scim }

      expect(response).to be_ok
      expect(JSON.parse(response.body)).to include('patch' => {'supported' => true})
      expect(JSON.parse(response.body)).to_not include('uses_defaults' => true)
      expect(JSON.parse(response.body)).to include('filter' => {'maxResults' => Scimitar::Filter::MAX_RESULTS_DEFAULT, 'supported' => true})
    end
  end

end
