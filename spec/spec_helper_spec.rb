# Self-test. Sometimes tests call into utility methods in spec_helper.rb;
# if those aren't doing what they should, then the tests might give false
# positive passes.
#
require 'spec_helper'

RSpec.describe 'spec_helper.rb self-test' do
  context '#spec_helper_hupcase' do
    it 'converts a flat Hash, preserving data type of keys' do
      input  = {:one => 1, 'two' => 2}
      output = spec_helper_hupcase(input)

      expect(output).to eql({:ONE => 1, 'TWO' => 2})
    end

    it 'converts a nested Hash' do
      input  = {:one => 1, 'two' => {:tHrEe => {'fOuR' => 4}}}
      output = spec_helper_hupcase(input)

      expect(output).to eql({:ONE => 1, 'TWO' => {:THREE => {'FOUR' => 4}}})
    end

    it 'converts an Array with Hashes' do
      input  = {:one => 1, 'two' => [true, 42, {:tHrEe => {'fOuR' => 4}}]}
      output = spec_helper_hupcase(input)

      expect(output).to eql({:ONE => 1, 'TWO' => [true, 42, {:THREE => {'FOUR' => 4}}]})
    end
  end # "context '#spec_helper_hupcase' do"
end
