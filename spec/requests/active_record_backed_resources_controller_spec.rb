require 'spec_helper'
require 'time'

RSpec.describe Scimitar::ActiveRecordBackedResourcesController do
  before :each do
    allow_any_instance_of(Scimitar::ApplicationController).to receive(:authenticated?).and_return(true)

    lmt = Time.parse("2023-01-09 14:25:00 +1300")

    @u1 = MockUser.create(username: '1', first_name: 'Foo', last_name: 'Ark', home_email_address: 'home_1@test.com', scim_uid: '001', created_at: lmt, updated_at: lmt + 1)
    @u2 = MockUser.create(username: '2', first_name: 'Foo', last_name: 'Bar', home_email_address: 'home_2@test.com', scim_uid: '002', created_at: lmt, updated_at: lmt + 2)
    @u3 = MockUser.create(username: '3', first_name: 'Foo',                   home_email_address: 'home_3@test.com', scim_uid: '003', created_at: lmt, updated_at: lmt + 3)
  end

  # ===========================================================================

  context '#index' do
    context 'with no items' do
      it 'returns empty list' do
        MockUser.delete_all

        expect_any_instance_of(MockUsersController).to receive(:index).once.and_call_original
        get '/Users', params: { format: :scim }

        expect(response.status).to eql(200)
        result = JSON.parse(response.body)

        expect(result['totalResults']).to eql(0)
        expect(result['startIndex'  ]).to eql(1)
        expect(result['itemsPerPage']).to eql(100)
      end
    end # "context 'with no items' do"

    context 'with items' do
      it 'returns all items' do
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

      it 'applies a filter, with case-insensitive value comparison' do
        get '/Users', params: {
          format: :scim,
          filter: 'name.givenName eq "FOO" and name.familyName pr and emails ne "home_1@test.com"'
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

      it 'applies a filter, with case-insensitive attribute matching (GitHub issue #37)' do
        get '/Users', params: {
          format: :scim,
          filter: 'name.GIVENNAME eq "Foo" and name.Familyname pr and emails ne "home_1@test.com"'
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

      # Strange attribute capitalisation in tests here builds on test coverage
      # for now-fixed GitHub issue #37.
      #
      context '"meta" / IDs (GitHub issue #36)' do
        it 'applies a filter on primary keys, using direct comparison (rather than e.g. case-insensitive operators)' do
          get '/Users', params: {
            format: :scim,
            filter: "id eq \"#{@u3.id}\""
          }

          expect(response.status).to eql(200)
          result = JSON.parse(response.body)

          expect(result['totalResults']).to eql(1)
          expect(result['Resources'].size).to eql(1)

          ids = result['Resources'].map { |resource| resource['id'] }
          expect(ids).to match_array([@u3.id.to_s])

          usernames = result['Resources'].map { |resource| resource['userName'] }
          expect(usernames).to match_array(['3'])
        end

        it 'applies a filter on external IDs, using direct comparison' do
          get '/Users', params: {
            format: :scim,
            filter: "externalID eq \"#{@u2.scim_uid}\""
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

        it 'applies a filter on "meta" entries, using direct comparison' do
          get '/Users', params: {
            format: :scim,
            filter: "Meta.LastModified eq \"#{@u3.updated_at}\""
          }

          expect(response.status).to eql(200)
          result = JSON.parse(response.body)

          expect(result['totalResults']).to eql(1)
          expect(result['Resources'].size).to eql(1)

          ids = result['Resources'].map { |resource| resource['id'] }
          expect(ids).to match_array([@u3.id.to_s])

          usernames = result['Resources'].map { |resource| resource['userName'] }
          expect(usernames).to match_array(['3'])
        end
      end # "context '"meta" / IDs (GitHub issue #36)' do"

      it 'obeys a page size' do
        get '/Users', params: {
          format: :scim,
          count:  2
        }

        expect(response.status).to eql(200)
        result = JSON.parse(response.body)

        expect(result['totalResults']).to eql(3)
        expect(result['Resources'].size).to eql(2)

        ids = result['Resources'].map { |resource| resource['id'] }
        expect(ids).to match_array([@u1.id.to_s, @u2.id.to_s])

        usernames = result['Resources'].map { |resource| resource['userName'] }
        expect(usernames).to match_array(['1', '2'])
      end

      it 'obeys start-at-1 offsets' do
        get '/Users', params: {
          format:    :scim,
          startIndex: 2
        }

        expect(response.status).to eql(200)
        result = JSON.parse(response.body)

        expect(result['totalResults']).to eql(3)
        expect(result['Resources'].size).to eql(2)

        ids = result['Resources'].map { |resource| resource['id'] }
        expect(ids).to match_array([@u2.id.to_s, @u3.id.to_s])

        usernames = result['Resources'].map { |resource| resource['userName'] }
        expect(usernames).to match_array(['2', '3'])
      end
    end # "context 'with items' do"

    context 'with bad calls' do
      it 'complains about bad filters' do
        get '/Users', params: {
          format: :scim,
          filter: 'name.givenName'
        }

        expect(response.status).to eql(400)
        result = JSON.parse(response.body)
        expect(result['scimType']).to eql('invalidFilter')
      end
    end # "context 'with bad calls' do"
  end # "context '#index' do"

  # ===========================================================================

  context '#show' do
    it 'shows an item' do
      expect_any_instance_of(MockUsersController).to receive(:show).once.and_call_original
      get "/Users/#{@u2.id}", params: { format: :scim }

      expect(response.status).to eql(200)
      result = JSON.parse(response.body)

      expect(result['id']).to eql(@u2.id.to_s) # Note - ID was converted String; not Integer
      expect(result['userName']).to eql('2')
      expect(result['name']['familyName']).to eql('Bar')
      expect(result['meta']['resourceType']).to eql('User')
    end

    it 'renders 404' do
      get '/Users/xyz', params: { format: :scim }

      expect(response.status).to eql(404)
      result = JSON.parse(response.body)
      expect(result['status']).to eql('404')
    end
  end # "context '#show' do"

  # ===========================================================================

  context '#create' do
    context 'creates an item' do
      shared_examples 'a creator' do | force_upper_case: |
        it 'with minimal parameters' do
          mock_before = MockUser.all.to_a

          attributes = { userName: '4' }  # Minimum required by schema
          attributes = spec_helper_hupcase(attributes) if force_upper_case

          expect_any_instance_of(MockUsersController).to receive(:create).once.and_call_original
          expect {
            post "/Users", params: attributes.merge(format: :scim)
          }.to change { MockUser.count }.by(1)

          mock_after = MockUser.all.to_a
          new_mock = (mock_after - mock_before).first

          expect(response.status).to eql(201)
          result = JSON.parse(response.body)

          expect(result['id']).to eql(new_mock.id.to_s)
          expect(result['meta']['resourceType']).to eql('User')
          expect(new_mock.username).to eql('4')
        end

        # A bit of extra coverage just for general confidence.
        #
        it 'with more comprehensive parameters' do
          mock_before = MockUser.all.to_a

          attributes = {
            userName: '4',
            name: {
              givenName: 'Given',
              familyName: 'Family'
            },
            meta: { resourceType: 'User' },
            emails: [
              {
                type: 'work',
                value: 'work_4@test.com'
              },
              {
                type: 'home',
                value: 'home_4@test.com'
              }
            ]
          }

          attributes = spec_helper_hupcase(attributes) if force_upper_case

          expect {
            post "/Users", params: attributes.merge(format: :scim)
          }.to change { MockUser.count }.by(1)

          mock_after = MockUser.all.to_a
          new_mock = (mock_after - mock_before).first

          expect(response.status).to eql(201)
          result = JSON.parse(response.body)

          expect(result['id']).to eql(new_mock.id.to_s)
          expect(result['meta']['resourceType']).to eql('User')
          expect(new_mock.username).to eql('4')
          expect(new_mock.first_name).to eql('Given')
          expect(new_mock.last_name).to eql('Family')
          expect(new_mock.home_email_address).to eql('home_4@test.com')
          expect(new_mock.work_email_address).to eql('work_4@test.com')
        end
      end # "shared_examples 'a creator' do | force_upper_case: |"

      context 'using schema-matched case' do
        it_behaves_like 'a creator', force_upper_case: false
      end # "context 'using schema-matched case' do"

      context 'using upper case' do
        it_behaves_like 'a creator', force_upper_case: true
      end # "context 'using upper case' do"
    end

    it 'returns 409 for duplicates (by Rails validation)' do
      expect_any_instance_of(MockUsersController).to receive(:create).once.and_call_original
      expect {
        post "/Users", params: {
          format: :scim,
          userName: '1' # Already exists
        }
      }.to_not change { MockUser.count }

      expect(response.status).to eql(409)
      result = JSON.parse(response.body)
      expect(result['scimType']).to eql('uniqueness')
      expect(result['detail']).to include('already been taken')
    end

    it 'notes schema validation failures' do
      expect {
        post "/Users", params: {
          format: :scim
          # userName parameter is required by schema, but missing
        }
      }.to_not change { MockUser.count }

      expect(response.status).to eql(400)
      result = JSON.parse(response.body)
      expect(result['scimType']).to eql('invalidValue')
      expect(result['detail']).to include('is required')
    end

    it 'notes Rails validation failures' do
      expect {
        post "/Users", params: {
          format: :scim,
          userName: MockUser::INVALID_USERNAME
        }
      }.to_not change { MockUser.count }

      expect(response.status).to eql(400)
      result = JSON.parse(response.body)

      expect(result['scimType']).to eql('invalidValue')
      expect(result['detail']).to include('is reserved')
    end
  end # "context '#create' do"

  # ===========================================================================

  context '#replace' do
    shared_examples 'a replacer' do | force_upper_case: |
      it 'which replaces all attributes in an instance' do
        attributes = { userName: '4' }  # Minimum required by schema
        attributes = spec_helper_hupcase(attributes) if force_upper_case

        expect_any_instance_of(MockUsersController).to receive(:replace).once.and_call_original
        expect {
          put "/Users/#{@u2.id}", params: attributes.merge(format: :scim)
        }.to_not change { MockUser.count }

        expect(response.status).to eql(200)
        result = JSON.parse(response.body)

        expect(result['id']).to eql(@u2.id.to_s)
        expect(result['meta']['resourceType']).to eql('User')

        @u2.reload

        expect(@u2.username).to eql('4')
        expect(@u2.first_name).to be_nil
        expect(@u2.last_name).to be_nil
        expect(@u2.home_email_address).to be_nil
      end
    end # "shared_examples 'a replacer' do | force_upper_case: |"

    context 'using schema-matched case' do
      it_behaves_like 'a replacer', force_upper_case: false
    end # "context 'using schema-matched case' do"

    context 'using upper case' do
      it_behaves_like 'a replacer', force_upper_case: true
    end # "context 'using upper case' do"

    it 'notes schema validation failures' do
      expect {
        put "/Users/#{@u2.id}", params: {
          format: :scim
          # userName parameter is required by schema, but missing
        }
      }.to_not change { MockUser.count }

      expect(response.status).to eql(400)
      result = JSON.parse(response.body)
      expect(result['scimType']).to eql('invalidValue')
      expect(result['detail']).to include('is required')

      @u2.reload

      expect(@u2.username).to eql('2')
      expect(@u2.first_name).to eql('Foo')
      expect(@u2.last_name).to eql('Bar')
      expect(@u2.home_email_address).to eql('home_2@test.com')
    end

    it 'notes Rails validation failures' do
      expect {
        post "/Users", params: {
          format: :scim,
          userName: MockUser::INVALID_USERNAME
        }
      }.to_not change { MockUser.count }

      expect(response.status).to eql(400)
      result = JSON.parse(response.body)

      expect(result['scimType']).to eql('invalidValue')
      expect(result['detail']).to include('is reserved')

      @u2.reload

      expect(@u2.username).to eql('2')
      expect(@u2.first_name).to eql('Foo')
      expect(@u2.last_name).to eql('Bar')
      expect(@u2.home_email_address).to eql('home_2@test.com')
    end

    it 'returns 404 if ID is invalid' do
      expect {
        put '/Users/xyz', params: {
          format: :scim,
          userName: '4' # Minimum required by schema
        }
      }.to_not change { MockUser.count }

      expect(response.status).to eql(404)
      result = JSON.parse(response.body)
      expect(result['status']).to eql('404')
    end
  end # "context '#replace' do"

  # ===========================================================================

  context '#update' do
    shared_examples 'an updater' do | force_upper_case: |
      it 'which patches specific attributes' do
        payload = {
          Operations: [
            {
              op: 'add',
              path: 'userName',
              value: '4'
            },
            {
              op: 'replace',
              path: 'emails[type eq "work"]',
              value: { type: 'work', value: 'work_4@test.com' }
            }
          ]
        }

        payload = spec_helper_hupcase(payload) if force_upper_case

        expect_any_instance_of(MockUsersController).to receive(:update).once.and_call_original
        expect {
          patch "/Users/#{@u2.id}", params: payload.merge(format: :scim)
        }.to_not change { MockUser.count }

        expect(response.status).to eql(200)
        result = JSON.parse(response.body)

        expect(result['id']).to eql(@u2.id.to_s)
        expect(result['meta']['resourceType']).to eql('User')

        @u2.reload

        expect(@u2.username).to eql('4')
        expect(@u2.first_name).to eql('Foo')
        expect(@u2.last_name).to eql('Bar')
        expect(@u2.home_email_address).to eql('home_2@test.com')
        expect(@u2.work_email_address).to eql('work_4@test.com')
      end

      context 'which clears attributes' do
        before :each do
          @u2.update!(work_email_address: 'work_2@test.com')
        end

        it 'with simple paths' do
          payload = {
            Operations: [
              {
                op: 'remove',
                path: 'name.givenName'
              }
            ]
          }

          payload = spec_helper_hupcase(payload) if force_upper_case

          expect_any_instance_of(MockUsersController).to receive(:update).once.and_call_original
          expect {
            patch "/Users/#{@u2.id}", params: payload.merge(format: :scim)
          }.to_not change { MockUser.count }

          expect(response.status).to eql(200)
          result = JSON.parse(response.body)

          expect(result['id']).to eql(@u2.id.to_s)
          expect(result['meta']['resourceType']).to eql('User')

          @u2.reload

          expect(@u2.username).to eql('2')
          expect(@u2.first_name).to be_nil
          expect(@u2.last_name).to eql('Bar')
          expect(@u2.home_email_address).to eql('home_2@test.com')
          expect(@u2.work_email_address).to eql('work_2@test.com')
        end

        it 'by array entry filter match' do
          payload = {
            Operations: [
              {
                op: 'remove',
                path: 'emails[type eq "work"]'
              }
            ]
          }

          payload = spec_helper_hupcase(payload) if force_upper_case

          expect_any_instance_of(MockUsersController).to receive(:update).once.and_call_original
          expect {
            patch "/Users/#{@u2.id}", params: payload.merge(format: :scim)
          }.to_not change { MockUser.count }

          expect(response.status).to eql(200)
          result = JSON.parse(response.body)

          expect(result['id']).to eql(@u2.id.to_s)
          expect(result['meta']['resourceType']).to eql('User')

          @u2.reload

          expect(@u2.username).to eql('2')
          expect(@u2.first_name).to eql('Foo')
          expect(@u2.last_name).to eql('Bar')
          expect(@u2.home_email_address).to eql('home_2@test.com')
          expect(@u2.work_email_address).to be_nil
        end

        it 'by whole collection' do
          payload = {
            Operations: [
              {
                op: 'remove',
                path: 'emails'
              }
            ]
          }

          payload = spec_helper_hupcase(payload) if force_upper_case

          expect_any_instance_of(MockUsersController).to receive(:update).once.and_call_original
          expect {
            patch "/Users/#{@u2.id}", params: payload.merge(format: :scim)
          }.to_not change { MockUser.count }

          expect(response.status).to eql(200)
          result = JSON.parse(response.body)

          expect(result['id']).to eql(@u2.id.to_s)
          expect(result['meta']['resourceType']).to eql('User')

          @u2.reload

          expect(@u2.username).to eql('2')
          expect(@u2.first_name).to eql('Foo')
          expect(@u2.last_name).to eql('Bar')
          expect(@u2.home_email_address).to be_nil
          expect(@u2.work_email_address).to be_nil
        end
      end # "context 'which clears attributes' do"
    end # "shared_examples 'an updater' do | force_upper_case: |"

    context 'using schema-matched case' do
      it_behaves_like 'an updater', force_upper_case: false
    end # "context 'using schema-matched case' do"

    context 'using upper case' do
      it_behaves_like 'an updater', force_upper_case: true
    end # "context 'using upper case' do"

    it 'notes Rails validation failures' do
      expect {
        patch "/Users/#{@u2.id}", params: {
          format: :scim,
          Operations: [
            {
              op: 'add',
              path: 'userName',
              value: MockUser::INVALID_USERNAME
            }
          ]
        }
      }.to_not change { MockUser.count }

      expect(response.status).to eql(400)
      result = JSON.parse(response.body)

      expect(result['scimType']).to eql('invalidValue')
      expect(result['detail']).to include('is reserved')

      @u2.reload

      expect(@u2.username).to eql('2')
      expect(@u2.first_name).to eql('Foo')
      expect(@u2.last_name).to eql('Bar')
      expect(@u2.home_email_address).to eql('home_2@test.com')
    end

    it 'returns 404 if ID is invalid' do
      expect {
        patch '/Users/xyz', params: {
          format: :scim,
          Operations: [
            {
              op: 'add',
              path: 'userName',
              value: '4'
            }
          ]
        }
      }.to_not change { MockUser.count }

      expect(response.status).to eql(404)
      result = JSON.parse(response.body)
      expect(result['status']).to eql('404')
    end
  end # "context '#update' do"

  # ===========================================================================

  context '#destroy' do
    it 'deletes an item if given no blok' do
      expect_any_instance_of(MockUsersController).to receive(:destroy).once.and_call_original
      expect_any_instance_of(MockUser).to receive(:destroy!).once.and_call_original
      expect {
        delete "/Users/#{@u2.id}", params: { format: :scim }
      }.to change { MockUser.count }.by(-1)

      expect(response.status).to eql(204)
      expect(response.body).to be_empty
    end

    it 'invokes a block if given one' do
      expect_any_instance_of(CustomDestroyMockUsersController).to receive(:destroy).once.and_call_original
      expect_any_instance_of(MockUser).to_not receive(:destroy!)

      expect {
        delete "/CustomDestroyUsers/#{@u2.id}", params: { format: :scim }
      }.to_not change { MockUser.count }

      expect(response.status).to eql(204)
      expect(response.body).to be_empty

      @u2.reload
      expect(@u2.username).to eql(CustomDestroyMockUsersController::NOT_REALLY_DELETED_USERNAME_INDICATOR)
    end

    it 'returns 404 if ID is invalid' do
      expect {
        delete '/Users/xyz', params: { format: :scim }
      }.to_not change { MockUser.count }

      expect(response.status).to eql(404)
      result = JSON.parse(response.body)
      expect(result['status']).to eql('404')
    end
  end # "context '#destroy' do"

  # ===========================================================================

  context 'service methods' do
    context '#storage_scope' do
      it 'raises "not implemented" to warn subclass authors' do
        expect { described_class.new.send(:storage_scope) }.to raise_error(NotImplementedError)
      end
    end # "context '#storage_class' do"
  end # "context 'service methods' do"
end
