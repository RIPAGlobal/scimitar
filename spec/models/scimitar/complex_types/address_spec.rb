require 'spec_helper'

RSpec.describe Scimitar::ComplexTypes::Address do
  context '#as_json' do
    it 'assumes no defaults' do
      expect(described_class.new.as_json).to eq({})
    end

    it 'allows a custom address type' do
      expect(described_class.new(type: 'home').as_json).to eq('type' => 'home')
    end

    it 'shows the set address' do
      expect(described_class.new(country: 'NZ').as_json).to eq('country' => 'NZ')
    end
  end

end
