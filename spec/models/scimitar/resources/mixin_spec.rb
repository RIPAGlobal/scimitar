require 'spec_helper'

RSpec.describe Scimitar::Resources::Mixin do

  # ===========================================================================
  # Internal classes used in some tests
  # ===========================================================================

  class StaticMapTest
    include ActiveModel::Model

    attr_accessor :work_email_address,
                  :home_email_address

    def self.scim_resource_type
      return Scimitar::Resources::User
    end

    def self.scim_attributes_map
      return {
        emails: [
          {
            match: 'type',
            with:  'work',
            using: {
              value:   :work_email_address,
              primary: false
            }
          },
          {
            match: 'type',
            with:  'home',
            using: { value: :home_email_address }
          }
        ]
      }
    end

    def self.scim_mutable_attributes
      return nil
    end

    def self.scim_queryable_attributes
      return nil
    end

    include Scimitar::Resources::Mixin
  end

  class DynamicMapTest
    include ActiveModel::Model

    attr_accessor :groups

    def self.scim_resource_type
      return Scimitar::Resources::User
    end

    def self.scim_attributes_map
      return {
        groups: [
          {
            list:  :groups,
            using: {
              value:   :id,        # <-- i.e. DynamicMapTest.groups[n].id
              display: :full_name  # <-- i.e. DynamicMapTest.groups[n].full_name
            }
          }
        ]
      }
    end

    def self.scim_mutable_attributes
      return nil
    end

    def self.scim_queryable_attributes
      return nil
    end

    include Scimitar::Resources::Mixin
  end

  # ===========================================================================
  # Errant class definitions
  # ===========================================================================

  context 'with bad class definitions' do
    it 'complains about missing mandatory methods' do
      mandatory_class_methods = %w{
        scim_resource_type
        scim_attributes_map
        scim_mutable_attributes
        scim_queryable_attributes
      }

      mandatory_class_methods.each do | required_class_method |

        # E.g. "You must define ::scim_resource_type in #<Class:...>"
        #
        expect {
          klass = Class.new(BasicObject) do
            fewer_class_methods = mandatory_class_methods - [required_class_method]
            fewer_class_methods.each do | method_to_define |
              define_singleton_method(method_to_define) do
                puts 'I am defined'
              end
            end

            include Scimitar::Resources::Mixin
          end
        }.to raise_error(RuntimeError, /#{Regexp.escape(required_class_method)}/)
      end
    end
  end # "context 'with bad class definitions' do"

  # ===========================================================================
  # Correct class definitions
  # ===========================================================================

  context 'with good class definitons' do

    require_relative '../../../apps/dummy/app/models/mock_user.rb'

    # ===========================================================================
    # Support methods
    # ===========================================================================

    context '#scim_queryable_attributes' do
      it 'exposes queryable attributes as an instance method' do
        instance_result = MockUser.new.scim_queryable_attributes()
        class_result    = MockUser.scim_queryable_attributes()

        expect(instance_result).to match_array(class_result)
      end
    end # "context '#scim_queryable_attributes' do"

    context '#scim_mutable_attributes' do
      it 'self-compiles mutable attributes and exposes them as an instance method' do
        readwrite_attrs = MockUser::READWRITE_ATTRS.map(&:to_sym)
        readwrite_attrs.delete(:id) # Should never be offered as writable in SCIM

        result = MockUser.new.scim_mutable_attributes()
        expect(result).to match_array(readwrite_attrs)
      end
    end # "context '#scim_mutable_attributes' do"

    # ===========================================================================
    # #to_scim
    # ===========================================================================

    context '#to_scim' do
      it 'compiles instance attribute values into a SCIM representation' do
        instance                    = MockUser.new
        instance.id                 = 42
        instance.scim_uid           = 'AA02984'
        instance.username           = 'foo'
        instance.first_name         = 'Foo'
        instance.last_name          = 'Bar'
        instance.work_email_address = 'foo.bar@test.com'
        instance.work_phone_number  = '+642201234567'

        scim = instance.to_scim(location: 'https://test.com/mock_users/42')
        json = scim.to_json()
        hash = JSON.parse(json)

        expect(hash).to eql({
          'userName'    => 'foo',
          'name'        => {'givenName'=>'Foo', 'familyName'=>'Bar'},
          'active'      => true,
          'emails'      => [{'type'=>'work', 'primary'=>true,  'value'=>'foo.bar@test.com'}], # Note, 'type' present
          'phoneNumbers'=> [{'type'=>'work', 'primary'=>false, 'value'=>'+642201234567'   }], # Note, 'type' present
          'id'          => '42', # Note, String
          'externalId'  => 'AA02984',
          'meta'        => {'location'=>'https://test.com/mock_users/42', 'resourceType'=>'User'},
          'schemas'     => ['urn:ietf:params:scim:schemas:core:2.0:User']
        })
      end

      context 'with optional timestamps' do
        context 'creation only' do
          class CreationOnlyTest < MockUser
            attr_accessor :created_at

            def self.scim_timestamps_map
              { created: :created_at }
            end
          end

          it 'renders the creation date/time' do
            instance            = CreationOnlyTest.new
            instance.created_at = Time.now

            scim = instance.to_scim(location: 'https://test.com/mock_users/42')
            json = scim.to_json()
            hash = JSON.parse(json)

            expect(hash['meta']).to eql({
              'created'      => instance.created_at.iso8601(0),
              'location'     => 'https://test.com/mock_users/42',
              'resourceType' => 'User'
            })
          end
        end # "context 'creation only' do"

        context 'update only' do
          class UpdateOnlyTest < MockUser
            attr_accessor :updated_at

            def self.scim_timestamps_map
              { lastModified: :updated_at }
            end
          end

          it 'renders the modification date/time' do
            instance            = UpdateOnlyTest.new
            instance.updated_at = Time.now

            scim = instance.to_scim(location: 'https://test.com/mock_users/42')
            json = scim.to_json()
            hash = JSON.parse(json)

            expect(hash['meta']).to eql({
              'lastModified' => instance.updated_at.iso8601(0),
              'location'     => 'https://test.com/mock_users/42',
              'resourceType' => 'User'
            })
          end
        end # "context 'update only' do"

        context 'create and update' do
          class CreateAndUpdateTest < MockUser
            attr_accessor :created_at, :updated_at

            def self.scim_timestamps_map
              {
                created:      :created_at,
                lastModified: :updated_at
              }
            end
          end

          it 'renders the creation and modification date/times' do
            instance            = CreateAndUpdateTest.new
            instance.created_at = Time.now - 1.month
            instance.updated_at = Time.now

            scim = instance.to_scim(location: 'https://test.com/mock_users/42')
            json = scim.to_json()
            hash = JSON.parse(json)

            expect(hash['meta']).to eql({
              'created'      => instance.created_at.iso8601(0),
              'lastModified' => instance.updated_at.iso8601(0),
              'location'     => 'https://test.com/mock_users/42',
              'resourceType' => 'User'
            })
          end
        end # "context 'create and update' do"
      end # "context 'with optional timestamps' do"

      context 'with arrays' do
        context 'using static mappings' do
          it 'converts to a SCIM representation' do
            instance = StaticMapTest.new(work_email_address: 'work@test.com', home_email_address: 'home@test.com')
            scim     = instance.to_scim(location: 'https://test.com/static_map_test')
            json     = scim.to_json()
            hash     = JSON.parse(json)

            expect(hash).to eql({
              'emails' => [
                {'type'=>'work', 'primary'=>false, 'value'=>'work@test.com'},
                {'type'=>'home',                   'value'=>'home@test.com'},
              ],

              'meta'    => {'location'=>'https://test.com/static_map_test', 'resourceType'=>'User'},
              'schemas' => ['urn:ietf:params:scim:schemas:core:2.0:User']
            })
          end
        end # "context 'using static mappings' do"

        context 'using dynamic lists' do
          it 'converts to a SCIM representation' do
            group  = Struct.new(:id, :full_name, keyword_init: true)
            groups = [
              group.new(id: 1, full_name: 'Group 1'),
              group.new(id: 2, full_name: 'Group 2'),
              group.new(id: 3, full_name: 'Group 3'),
            ]

            instance = DynamicMapTest.new(groups: groups)
            scim     = instance.to_scim(location: 'https://test.com/dynamic_map_test')
            json     = scim.to_json()
            hash     = JSON.parse(json)

            expect(hash).to eql({
              'groups' => [
                {'display'=>'Group 1', 'value'=>'1'},
                {'display'=>'Group 2', 'value'=>'2'},
                {'display'=>'Group 3', 'value'=>'3'},
              ],

              'meta'    => {'location'=>'https://test.com/dynamic_map_test', 'resourceType'=>'User'},
              'schemas' => ['urn:ietf:params:scim:schemas:core:2.0:User']
            })
          end
        end # "context 'using dynamic lists' do"
      end # "context 'with arrays' do"
    end # "context '#to_scim' do"

    # ===========================================================================
    # #from_scim!
    # ===========================================================================

    xcontext '#from_scim!' do
      it 'writes instance attribute values from a SCIM representation' do
        # instance                    = MockUser.new
        # instance.id                 = 42
        # instance.scim_uid           = 'AA02984'
        # instance.username           = 'foo'
        # instance.first_name         = 'Foo'
        # instance.last_name          = 'Bar'
        # instance.work_email_address = 'foo.bar@test.com'
        # instance.work_phone_number  = '+642201234567'
        #
        # scim = instance.to_scim(location: 'https://test.com/mock_users/42')
        # json = scim.to_json()
        # hash = JSON.parse(json)
        #
        # expect(hash).to eql({
        #   'userName'    => 'foo',
        #   'name'        => {'givenName'=>'Foo', 'familyName'=>'Bar'},
        #   'active'      => true,
        #   'emails'      => [{'type'=>'work', 'primary'=>true,  'value'=>'foo.bar@test.com'}], # Note, 'type' present
        #   'phoneNumbers'=> [{'type'=>'work', 'primary'=>false, 'value'=>'+642201234567'   }], # Note, 'type' present
        #   'id'          => '42', # Note, String
        #   'externalId'  => 'AA02984',
        #   'meta'        => {'location'=>'https://test.com/mock_users/42', 'resourceType'=>'User'},
        #   'schemas'     => ['urn:ietf:params:scim:schemas:core:2.0:User']
        # })
      end

      context 'with arrays' do
        context 'using static mappings' do
          it 'converts the SCIM data to appropriate attributes' do
            # instance = StaticMapTest.new(work_email_address: 'work@test.com', home_email_address: 'home@test.com')
            # scim     = instance.to_scim(location: 'https://test.com/static_map_test')
            # json     = scim.to_json()
            # hash     = JSON.parse(json)
            #
            # expect(hash).to eql({
            #   'emails' => [
            #     {'type'=>'work', 'primary'=>false, 'value'=>'work@test.com'},
            #     {'type'=>'home',                   'value'=>'home@test.com'},
            #   ],
            #
            #   'meta'    => {'location'=>'https://test.com/static_map_test', 'resourceType'=>'User'},
            #   'schemas' => ['urn:ietf:params:scim:schemas:core:2.0:User']
            # })
          end
        end # "context 'using static mappings' do"

        context 'using dynamic lists' do
          it 'converts the SCIM lists to collections on the appropriate attribute' do
            # group  = Struct.new(:id, :full_name, keyword_init: true)
            # groups = [
            #   group.new(id: 1, full_name: 'Group 1'),
            #   group.new(id: 2, full_name: 'Group 2'),
            #   group.new(id: 3, full_name: 'Group 3'),
            # ]
            #
            # instance = DynamicMapTest.new(groups: groups)
            # scim     = instance.to_scim(location: 'https://test.com/dynamic_map_test')
            # json     = scim.to_json()
            # hash     = JSON.parse(json)
            #
            # expect(hash).to eql({
            #   'groups' => [
            #     {'display'=>'Group 1', 'value'=>'1'},
            #     {'display'=>'Group 2', 'value'=>'2'},
            #     {'display'=>'Group 3', 'value'=>'3'},
            #   ],
            #
            #   'meta'    => {'location'=>'https://test.com/dynamic_map_test', 'resourceType'=>'User'},
            #   'schemas' => ['urn:ietf:params:scim:schemas:core:2.0:User']
            # })
          end
        end # "context 'using dynamic lists' do"
      end # "context 'with arrays' do"
    end # "context '#from_scim!' do"
  end # "context 'with good class definitons' do"
end # "RSpec.describe Scimitar::Resources::Mixin do"
