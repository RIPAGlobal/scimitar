require 'spec_helper'

RSpec.describe Scimitar::Lists::Count do
  before :each do
    @instance = described_class.new
  end

  context '#limit' do
    it 'defaults to 100' do
      expect(@instance.limit).to eql(100)
    end

    it 'converts input strings to integers' do
      @instance.limit = '50'
      expect(@instance.limit).to eql(50)
    end

    context 'error checking' do
      it 'complains about attempts to set non-numeric values' do
        expect { @instance.limit = 'A' }.to raise_error(RuntimeError)
      end

      it 'complains about attempts to set zero values' do
        expect { @instance.limit = '0' }.to raise_error(RuntimeError)
      end

      it 'complains about attempts to set zero values' do

        expect { @instance.limit = '-10' }.to raise_error(RuntimeError)
      end
    end # "context 'on-read error checking' do"
  end # "context '#limit' do"

  context '#start_index' do
    it 'defaults to 1' do
      expect(@instance.start_index).to eql(1)
    end

    it 'converts input strings to integers' do
      @instance.start_index = '12'
      expect(@instance.start_index).to eql(12)
    end

    it 'bounds zero values to 1' do
      @instance.start_index = '0'
      expect(@instance.start_index).to eql(1)
    end

    context 'error checking' do
      it 'complains about attempts to set non-numeric values' do

        expect { @instance.start_index = 'A' }.to raise_error(RuntimeError)
      end

      it 'complains about attempts to set negative values' do
        expect { @instance.start_index = '-10' }.to raise_error(RuntimeError)
      end
    end # "context 'on-read error checking' do"
  end # "context '#start_index' do"

  context '#offset' do
    it 'defaults to 0' do
      expect(@instance.offset).to eql(0)
    end

    it 'returns the #start_index minus one' do
      @instance.start_index = '12'
      expect(@instance.offset).to eql(11)
    end

    it 'is read-only' do
      expect { @instance.offset = 23 }.to raise_error(NoMethodError)
    end
  end # "context '#offset' do"

  context '#total' do
    it 'defaults to "nil" as "unknown"' do
      expect(@instance.total).to be_nil
    end

    it 'is read/write' do
      @instance.total = 23
      expect(@instance.total).to eql(23)
    end
  end # "context '#total' do"

  context 'instantiation' do
    it 'instantiates with parameters' do
      instance = described_class.new(start_index: '5', total: 45)

      expect(instance.limit      ).to eql(100)
      expect(instance.start_index).to eql(5)
      expect(instance.offset     ).to eql(4)
      expect(instance.total      ).to eql(45)
    end
  end # "context 'instantiation' do"
end # "RSpec.describe Scimitar::Lists::Count do"
