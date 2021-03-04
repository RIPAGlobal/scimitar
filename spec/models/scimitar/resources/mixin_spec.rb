require 'spec_helper'

RSpec.describe Scimitar::Resources::Mixin do

  # ===========================================================================
  # Errant class definitions
  # ===========================================================================
  #
  context 'with bad class definitions' do
    it 'complains about missing methods' do
      required_class_methods = %w{
        scim_resource_type
        scim_attributes_map
        scim_mutable_attributes
        scim_queryable_attributes
      }

      required_class_methods.each do | required_class_method |

        # E.g. "You must define ::scim_resource_type in #<Class:...>"
        #
        expect {
          klass = Class.new(BasicObject) do
            fewer_class_methods = required_class_methods - [required_class_method]
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
  #
  context 'with good class definitons' do

    require_relative '../../../apps/dummy/app/models/mock_user.rb'

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

    context '#to_scim' do
      it 'compiles instance attribute values into a SCIM representation' do
        instance                    = MockUser.new
        instance.id                 = 23
        instance.scim_uid           = 'AA02984'
        instance.username           = 'foo'
        instance.first_name         = 'Foo'
        instance.last_name          = 'Bar'
        instance.work_email_address = 'foo.bar@test.com'
        instance.work_phone_number  = '+642201234567'

        scim = instance.to_scim(location: 'https://test.com/mock_users/23')
        json = scim.to_json()
        hash = JSON.parse(json)

        expect(hash).to eql({
          'userName'    => 'foo',
          'name'        => {'givenName'=>'Foo', 'familyName'=>'Bar'},
          'active'      => true,
          'emails'      => [{'type'=>'work', 'primary'=>true, 'value'=>'foo.bar@test.com'}], # Note, 'type' and 'primary' present
          'phoneNumbers'=> [{'type'=>'work', 'primary'=>true, 'value'=>'+642201234567'   }], # Note, 'type' and 'primary' present
          'id'          => '23', # Note, String
          'externalId'  => 'AA02984',
          'meta'        => {'resourceType'=>'User'},
          'schemas'     => ['urn:ietf:params:scim:schemas:core:2.0:User']
        })
      end

      xcontext 'with arrays' do
        it 'handles static mappings' do
        end

        it 'handles dynamic lists' do
        end
      end # context 'with arrays' do
    end # "context '#to_scim' do"
  end # "context 'with good class definitons' do"
end # "RSpec.describe Scimitar::Resources::Mixin do"
