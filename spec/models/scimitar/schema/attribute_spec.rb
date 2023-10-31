require 'spec_helper'

RSpec.describe Scimitar::Schema::Attribute do
  context '#initialize' do
    it 'sets the default properties' do
      attribute = described_class.new
      expect(attribute.multiValued).to be(false)
      expect(attribute.required).to be(false)
      expect(attribute.caseExact).to be(false)
      expect(attribute.mutability).to eql('readWrite')
      expect(attribute.uniqueness).to eql('none')
      expect(attribute.returned).to eql('default')
    end
    it 'lets override the default properties' do
      attribute = described_class.new(multiValued: true)
      expect(attribute.multiValued).to be(true)
    end

    it 'transforms complexTypes into subAttributes' do
      name = described_class.new(name: 'name', complexType: Scimitar::ComplexTypes::Name)
      expect(name.type).to eql('complex')
      expect(name.subAttributes).to eql(Scimitar::Schema::Name.scim_attributes)
    end
  end

  context '#valid?' do
    it 'is invalid if attribute is required but value is blank' do
      attribute = described_class.new(name: 'userName', type: 'string', required: true)
      expect(attribute.valid?(nil)).to be(false)
      expect(attribute.errors.messages.to_h).to eql({userName: ['is required']})
    end

    it 'is valid if attribute is not required and  value is blank' do
      attribute = described_class.new(name: 'userName', type: 'string', required: false)
      expect(attribute.valid?(nil)).to be(true)
      expect(attribute.errors.messages.to_h).to eql({})
    end

    it 'is valid if type is string and given value is string' do
      expect(described_class.new(name: 'name', type: 'string').valid?('something')).to be(true)
    end

    it 'is invalid if type is string and given value is not string' do
      attribute = described_class.new(name: 'userName', type: 'string')
      expect(attribute.valid?(10)).to be(false)
      expect(attribute.errors.messages.to_h).to eql({userName: ['has the wrong type. It has to be a(n) string.']})
    end

    it 'is valid if multi-valued and type is string and given value is an array of strings' do
      attribute = described_class.new(name: 'scopes', multiValued: true, type: 'string')
      expect(attribute.valid?(['something', 'something else'])).to be(true)
    end

    it 'is valid if multi-valued and type is string and given value is an empty array' do
      attribute = described_class.new(name: 'scopes', multiValued: true, type: 'string')
      expect(attribute.valid?([])).to be(true)
    end

    it 'is invalid if multi-valued and type is string and given value is not an array' do
      attribute = described_class.new(name: 'scopes', multiValued: true, type: 'string')
      expect(attribute.valid?('something')).to be(false)
      expect(attribute.errors.messages.to_h).to eql({scopes: ['or one of its elements has the wrong type. It has to be an array of strings.']})
    end

    it 'is invalid if multi-valued and type is string and given value is an array containing another type' do
      attribute = described_class.new(name: 'scopes', multiValued: true, type: 'string')
      expect(attribute.valid?(['something', 123])).to be(false)
      expect(attribute.errors.messages.to_h).to eql({scopes: ['or one of its elements has the wrong type. It has to be an array of strings.']})
    end

    it 'is valid if type is boolean and given value is boolean' do
      expect(described_class.new(name: 'name', type: 'boolean').valid?(false)).to be(true)
      expect(described_class.new(name: 'name', type: 'boolean').valid?(true)).to be(true)
    end

    it 'is valid if type is complex and the schema is same' do
      expect(described_class.new(name: 'name', complexType: Scimitar::ComplexTypes::Name).valid?(Scimitar::ComplexTypes::Name.new(givenName: 'a', familyName: 'b'))).to be(true)
    end

    it 'is valid if type is integer and given value is integer (duh)' do
      expect(described_class.new(name: 'quantity', type: 'integer').valid?(123)).to be(true)
    end

    it 'is not valid if type is integer and given value is not an integer' do
      expect(described_class.new(name: 'quantity', type: 'integer').valid?(123.3)).to be(false)
    end

    it 'is valid if type is dateTime and given value is an ISO8601 date time' do
      expect(described_class.new(name: 'startDate', type: 'dateTime').valid?('2018-07-26T11:59:43-06:00')).to be(true)
    end

    it 'is not valid if type is dateTime and given value is a valid date but not in  ISO8601 format' do
      expect(described_class.new(name: 'startDate', type: 'dateTime').valid?('2018-07-26')).to be(false)
    end
    it 'is not valid if type is dateTime and given value is not a valid date' do
      expect(described_class.new(name: 'startDate', type: 'dateTime').valid?('gaga')).to be(false)
    end
  end
end
