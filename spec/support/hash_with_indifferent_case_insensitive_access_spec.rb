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

    context 'access and merging' do
      before :each do
        @original_subject = subject().to_h().dup()
      end

      it 'returns keys as Strings' do
        subject()[:foo] = 1
        subject()[:BAR] = 2

        expect(subject().keys).to match_array(@original_subject.keys + ['foo', 'BAR'])
      end

      it 'retains original case of keys' do
        subject()[:foo ] = 1
        subject()['FoO'] = 40 # (first-time-set case preservation test in passing)
        subject()[:BAR ] = 2
        subject()['Baz'] = 3

        expectation = @original_subject.merge({
          'foo' => 40,
          'BAR' => 2,
          'Baz' => 3
        })

        expect(subject()).to eql(expectation)
      end

      it '#merge does not mutate the receiver and retains case of first-set keys' do
        subject()[:foo] = 1
        subject()[:BAR] = 2

        pre_merge_subject = subject().dup()

        result      = subject().merge({:FOO => { 'onE' => 40 }, :Baz => 3})
        expectation = @original_subject.merge({
          'foo' => { 'onE' => 40 },
          'BAR' => 2,
          'Baz' => 3
        })

        expect(subject()).to eql(pre_merge_subject)
        expect(result).to eql(expectation)
      end

      it '#merge! mutates the receiver retains case of first-set keys' do
        subject()[:foo] = 1
        subject()[:BAR] = 2

        subject().merge!({:FOO => { 'onE' => 40 }, :Baz => 3})

        expectation = @original_subject.merge({
          'foo' => { 'onE' => 40 },
          'BAR' => 2,
          'Baz' => 3
        })

        expect(subject()).to eql(expectation)
      end

      it '#deep_merge does not mutate the receiver and retains nested key cases' do
        subject()[:foo] = { :one => 10 }
        subject()[:BAR] = 2

        pre_merge_subject = subject().dup()

        result      = subject().deep_merge({:FOO => { 'ONE' => 40, :TWO => 20 }, :Baz => 3})
        expectation = @original_subject.merge({
          'foo' => { 'one' => 40, 'TWO' => 20 },
          'BAR' => 2,
          'Baz' => 3
        })

        expect(subject()).to eql(pre_merge_subject)
        expect(result).to eql(expectation)
      end

      it '#deep_merge! mutates the receiver and retains nested key cases' do
        subject()[:foo] = { :one => 10 }
        subject()[:BAR] = 2

        subject().deep_merge!({:FOO => { 'ONE' => 40, :TWO => 20 }, :Baz => 3})

        expectation = @original_subject.merge({
          'foo' => { 'one' => 40, 'TWO' => 20 },
          'BAR' => 2,
          'Baz' => 3
        })

        expect(subject()).to eql(expectation)
      end

      it 'retains indifferent behaviour after duplication' do
        subject()[:foo] = { 'onE' => 40 }
        subject()[:BAR] = 2

        duplicate = subject().dup()
        duplicate.merge!({ 'FOO' => true, 'baz' => 3 })

        expectation = @original_subject.merge({
          'foo' => true,
          'BAR' => 2,
          'baz' => 3
        })

        expect(duplicate.to_h).to eql(expectation.to_h)
      end
    end # "context 'access and merging' do"
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
