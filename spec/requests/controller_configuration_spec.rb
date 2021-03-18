require 'spec_helper'

RSpec.describe 'Controller configuration' do
  before :each do
    allow_any_instance_of(Scimitar::ApplicationController).to receive(:authenticated?).and_return(true)
  end

  context 'application_controller_mixin' do
    it 'the test before-action declared in configuration gets called' do
      expect_any_instance_of(MockUsersController).to receive(:test_hook)

      get '/Users', params: { format: :scim }

      expect(response).to be_ok
    end
  end # "context 'application_controller_mixin' do"
end
