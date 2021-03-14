require 'spec_helper'

RSpec.describe Scimitar::ActiveRecordBackedResourcesController do
  before :each do
    allow_any_instance_of(Scimitar::ApplicationController).to receive(:authenticated?).and_return(true)
  end

  context 'lists' do
    it 'empty' do
      get '/Users', params: { format: :scim }

      expect(response.status).to eql(200)
      result = JSON.parse(response.body)

      expect(result['totalResults']).to eql(0)
      expect(result['startIndex'  ]).to eql(1)
      expect(result['itemsPerPage']).to eql(100)
    end

    context 'with items' do
      before :each do
        @u1 = MockUser.create(username: '1', first_name: 'Foo', last_name: 'Ark', home_email_address: 'home_1@test.com')
        @u2 = MockUser.create(username: '2', first_name: 'Foo', last_name: 'Bar', home_email_address: 'home_2@test.com')
        @u3 = MockUser.create(username: '3', first_name: 'Foo',                   home_email_address: 'home_3@test.com')
      end

      it 'without parameters' do
        get '/Users', params: { format: :scim }

        expect(response.status).to eql(200)
        result = JSON.parse(response.body)

        expect(result['totalResults']).to eql(3)
        expect(result['Resources'].size).to eql(3)

        ids = result['Resources'].map { |resource| resource['id'] }
        expect(ids).to match_array([@u1.id.to_s, @u2.id.to_s, @u3.id.to_s])

        usernames = result['Resources'].map { |resource| resource['userName'] }
        expect(usernames).to match_array(['1', '2', '3'])
      end

      it 'with a filter' do
        get '/Users', params: {
          format: :scim,
          filter: 'name.givenName eq "Foo" and name.familyName pr and emails ne "home_1@test.com"'
        }

        expect(response.status).to eql(200)
        result = JSON.parse(response.body)

        expect(result['totalResults']).to eql(1)
        expect(result['Resources'].size).to eql(1)

        ids = result['Resources'].map { |resource| resource['id'] }
        expect(ids).to match_array([@u2.id.to_s])

        usernames = result['Resources'].map { |resource| resource['userName'] }
        expect(usernames).to match_array(['2'])
      end

      it 'pagination' do
        get '/Users', params: {
          format: :scim,
          count:  2
        }

        expect(response.status).to eql(200)
        result = JSON.parse(response.body)

        expect(result['totalResults']).to eql(2)
        expect(result['Resources'].size).to eql(2)

        ids = result['Resources'].map { |resource| resource['id'] }
        expect(ids).to match_array([@u1.id.to_s, @u2.id.to_s])

        usernames = result['Resources'].map { |resource| resource['userName'] }
        expect(usernames).to match_array(['1', '2'])
      end

      it 'offsets' do
        get '/Users', params: {
          format:    :scim,
          startIndex: 2
        }

        expect(response.status).to eql(200)
        result = JSON.parse(response.body)

        expect(result['totalResults']).to eql(2)
        expect(result['Resources'].size).to eql(2)

        ids = result['Resources'].map { |resource| resource['id'] }
        expect(ids).to match_array([@u2.id.to_s, @u3.id.to_s])

        usernames = result['Resources'].map { |resource| resource['userName'] }
        expect(usernames).to match_array(['2', '3'])
      end
    end # "context 'with items' do"
  end # "context 'lists' do"
end
