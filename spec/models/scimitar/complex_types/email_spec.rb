require 'spec_helper'

RSpec.describe Scimitar::ComplexTypes::Email do
  context '#as_json' do
    it 'assumes no defaults' do
      expect(described_class.new.as_json).to eq({})
    end

    it 'allows a custom email type' do
      expect(described_class.new(type: 'home').as_json).to eq('type' => 'home')
    end

    it 'allows a non-primary email' do
      expect(described_class.new(primary: false).as_json).to eq('primary' => false)
    end

    it 'shows the set email' do
      expect(described_class.new(value: 'a@b.c').as_json).to eq('value' => 'a@b.c')
    end
  end

end

