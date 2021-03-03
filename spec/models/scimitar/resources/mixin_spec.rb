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
    class MixinTest
      def self.scim_resource_type
        return Scimitar::Resources::User
      end

      def self.scim_attributes_map
        return {
          id:         :id,
          externalId: :scim_uid,
          userName:   :email_address,
          name:       {
            givenName:  :name,
            familyName: :surname
          },
          emails: [
            {
              value: :email_address
            }
          ],
          phoneNumbers: [
            {
              value: :phone_number
            }
          ],
          active: :is_active
        }
      end

      def self.scim_mutable_attributes
        return nil
      end

      def self.scim_queryable_attributes
        return {
          givenName:  :name,
          familyName: :surname,
          emails:     :email_address,
        }
      end

      include Scimitar::Resources::Mixin
    end

    context '#scim_queryable_attributes' do
      it 'exposes queryable attributes as an instance method' do
        instance_result = MixinTest.new.scim_queryable_attributes()
        class_result    = MixinTest.scim_queryable_attributes()

        expect(instance_result).to match_array(class_result)
      end
    end # "context '#scim_queryable_attributes' do"

    context '#scim_mutable_attributes' do
      xit 'self-compiles mutable attributes and exposes them as an instance method' do
        result = MixinTest.new.scim_mutable_attributes()
      end
    end # "context '#scim_mutable_attributes' do"

    context '#to_scim' do
      xit 'compiles instance attribute values into a SCIM representation' do
      end
    end # "context '#to_scim' do"
  end # "context 'with good class definitons' do"
end # "RSpec.describe Scimitar::Resources::Mixin do"
