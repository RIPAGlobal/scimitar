require 'spec_helper'

RSpec.describe Scimitar::Schema::Base do
  context '#as_json' do
    it 'converts the scim_attributes to attributes' do
      attribute = Scimitar::Schema::Attribute.new(name: 'nickName')
      schema = described_class.new(scim_attributes: [attribute])
      expect(schema.as_json['attributes']).to eql([attribute.as_json])
      expect(schema.as_json['scim_attributes']).to be_nil
    end
  end

  context '#initialize' do
    it 'creates a meta' do
      schema = described_class.new
      expect(schema.meta.resourceType).to eql('Schema')
    end
  end

  context '.find_attribute' do
    it 'finds at top level' do
      found = Scimitar::Schema::User.find_attribute('password')
      expect(found).to be_present
      expect(found.name).to eql('password')
      expect(found.mutability).to eql('writeOnly')
    end

    it 'finds nested' do
      found = Scimitar::Schema::User.find_attribute('name', 'givenName')
      expect(found).to be_present
      expect(found.name).to eql('givenName')
      expect(found.mutability).to eql('readWrite')
    end

    it 'finds in multi-valued types, without index' do
      found = Scimitar::Schema::User.find_attribute('groups', 'type')
      expect(found).to be_present
      expect(found.name).to eql('type')
      expect(found.mutability).to eql('readOnly')
    end

    it 'finds in multi-valued types, ignoring index' do
      found = Scimitar::Schema::User.find_attribute('groups', 42, 'type')
      expect(found).to be_present
      expect(found.name).to eql('type')
      expect(found.mutability).to eql('readOnly')
    end

    it 'does not find bad names' do
      found = Scimitar::Schema::User.find_attribute('foo')
      expect(found).to be_nil
    end

    it 'does not find nested bad names' do
      found = Scimitar::Schema::User.find_attribute('name', 'foo')
      expect(found).to be_nil
    end

    it 'handles attempting to read sub-attributes when there are none' do
      found = Scimitar::Schema::User.find_attribute('password', 'foo')
      expect(found).to be_nil
    end
  end
end
