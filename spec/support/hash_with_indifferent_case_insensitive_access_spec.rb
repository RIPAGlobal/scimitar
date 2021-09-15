require 'spec_helper'

RSpec.describe Scimitar::Support::HashWithIndifferentCaseInsensitiveAccess do
  shared_examples 'an indifferent access, case insensitive Hash' do
    context 'where keys set as strings' do
      it 'can be retrieved via any case' do
        subject()['foo'] = 1

        expect(subject()['FOO']).to eql(1)
        expect(subject()[:FoO ]).to eql(1)
        expect(subject()['bar']).to be_nil
      end

      it 'can be checked for via any case' do
        subject()['foo'] = 1

        expect(subject()).to     have_key('FOO')
        expect(subject()).to     have_key(:FoO )
        expect(subject()).to_not have_key('bar')
      end
    end # "context 'where keys set as strings' do"

    context 'where keys set as symbols' do
      it 'retrieves via any case' do
        subject()[:foo] = 1

        expect(subject()['FOO']).to eql(1)
        expect(subject()[:FoO ]).to eql(1)
        expect(subject()['bar']).to be_nil
      end

      it 'enquires via any case' do
        subject()[:foo] = 1

        expect(subject()).to     have_key('FOO')
        expect(subject()).to     have_key(:FoO )
        expect(subject()).to_not have_key('bar')
      end
    end # "context 'where keys set as symbols' do"
  end # "shared_examples 'an indifferent access, case insensitive Hash' do"

  context 'when created directly' do
    subject do
      described_class.new()
    end

    it_behaves_like 'an indifferent access, case insensitive Hash'
  end # "context 'when created directly' do"

  context 'when created through conversion' do
    subject do
      { 'test' => 2 }.with_indifferent_access.with_indifferent_case_insensitive_access()
    end

    it 'includes the original data' do
      expect(subject()[:TEST]).to eql(2)
    end

    it_behaves_like 'an indifferent access, case insensitive Hash'
  end # "context 'converting hashes' do"
end
