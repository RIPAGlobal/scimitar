require 'spec_helper'

RSpec.describe Scimitar::Resources::Base do
  context '#valid?' do
    MyCustomSchema = Class.new(Scimitar::Schema::Base) do
      def self.id
        'custom-id'
      end

      def self.scim_attributes
        [
          Scimitar::Schema::Attribute.new(
            name: 'userName', type: 'string', required: false
          ),
          Scimitar::Schema::Attribute.new(
            name: 'enforce', type: 'boolean', required: true
          ),
          Scimitar::Schema::Attribute.new(
            name: 'complexName', complexType: Scimitar::ComplexTypes::Name, required: false
          ),
          Scimitar::Schema::Attribute.new(
            name: 'complexNames', complexType: Scimitar::ComplexTypes::Name, multiValued:true, required: false
          ),
          Scimitar::Schema::Attribute.new(
            name: 'vdtpTestByEmail', complexType: Scimitar::ComplexTypes::Email, required: false
          )
        ]
      end
    end

    MyCustomResource =  Class.new(Scimitar::Resources::Base) do
      set_schema MyCustomSchema
    end

    it 'adds validation errors to the resource for simple attributes' do
      resource = MyCustomResource.new(userName: 10)
      expect(resource.valid?).to be(false)
      expect(resource.errors.full_messages).to match_array(['Username has the wrong type. It has to be a(n) string.', 'Enforce is required'])
    end

    it 'adds validation errors to the resource for the complex attribute when the value does not match the schema' do
      resource = MyCustomResource.new(complexName: 10, enforce: false)
      expect(resource.valid?).to be(false)
      expect(resource.errors.full_messages).to match_array(['Complexname has to follow the complexType format.'])
    end

    it 'adds validation errors to the resource from what the complex type schema returns' do
      resource = MyCustomResource.new(complexName: { givenName: 10 }, enforce: false)
      expect(resource.valid?).to be(false)
      expect(resource.errors.full_messages).to match_array(["Complexname familyname is required", "Complexname givenname has the wrong type. It has to be a(n) string."])
    end

    it 'adds validation errors to the resource from what the complex type schema returns when it is multi-valued' do
      resource = MyCustomResource.new(complexNames: [
        "Jane Austen",
        { givenName: 'Jane', familyName: true }
      ],
      enforce: false)
      expect(resource.valid?).to be(false)
      expect(resource.errors.full_messages).to match_array(["Complexnames has to follow the complexType format.", "Complexnames familyname has the wrong type. It has to be a(n) string."])
    end

    context 'configuration of required values in VDTP schema' do
      around :each do | example |
        original_configuration = Scimitar.engine_configuration.optional_value_fields_required
        Scimitar::Schema::Email.instance_variable_set('@scim_attributes', nil)
        example.run()
      ensure
        Scimitar.engine_configuration.optional_value_fields_required = original_configuration
        Scimitar::Schema::Email.instance_variable_set('@scim_attributes', nil)
      end

      it 'requires a value by default' do
        resource = MyCustomResource.new(vdtpTestByEmail: { value: nil }, enforce: false)
        expect(resource.valid?).to be(false)
        expect(resource.errors.full_messages).to match_array(['Vdtptestbyemail value is required'])
      end

      it 'can be configured for optional values' do
        Scimitar.engine_configuration.optional_value_fields_required = false
        resource = MyCustomResource.new(vdtpTestByEmail: { value: nil }, enforce: false)
        expect(resource.valid?).to be(true)
      end
    end # "context 'configuration of required values in VDTP schema' do"
  end # "context '#valid?' do"
end
