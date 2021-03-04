require 'spec_helper'

RSpec.describe Scimitar::Lists::QueryParser do

  require_relative '../../../apps/dummy/app/models/mock_user.rb'

  # ===========================================================================
  # ATTRIBUTES
  # ===========================================================================

  context '#attribute' do
    it 'complains if there is no attribute present' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        ''
      )

      expect { instance.attribute() }.to raise_error(Scimitar::FilterError)
    end

    it 'complains if there is no attribute mapping available' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'externalId eq 12345678'
      )

      expect { instance.attribute() }.to raise_error(Scimitar::FilterError)
    end

    it 'returns the attribute' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'familyName eq BAZ'
      )

      expect(instance.attribute()).to eql(:last_name)
    end
  end # "context '#attribute' do"

  # ===========================================================================
  # OPERATORS
  # ===========================================================================

  context '#operator' do
    it 'complains if there is no operator present' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'familyName'
      )

      expect { instance.operator() }.to raise_error(Scimitar::FilterError)
    end

    it 'complains if the operator is unrecognised' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'familyName zz BAZ'
      )

      expect { instance.operator() }.to raise_error(Scimitar::FilterError)
    end

    it 'returns expected operators' do

      # Hand-written instead of using a constant, so we check one set of hand
      # drawn mappings against another and hopefully increase the chances of
      # spotting an error.
      #
      expected_mapping = {
        'eq' => '=',
        'ne' => '!=',
        'gt' => '>',
        'ge' => '>=',
        'lt' => '<',
        'le' => '<=',
        'co' => 'LIKE',
        'sw' => 'LIKE',
        'ew' => 'LIKE'
      }

      # Self-check: Is test coverage up to date?
      #
      expect(expected_mapping.keys).to match_array(Scimitar::Lists::QueryParser::SQL_COMPARISON_OPERATOR.keys)

      expected_mapping.each do | input, expected_output |
        instance = described_class.new(
          MockUser.new.scim_queryable_attributes(),
          "familyName #{input} BAZ"
        )

        expect(instance.operator()).to eql(expected_output)
      end
    end

    it 'handles "pr" (presence) checks' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        "familyName PR"
      )

      expect(instance.operator()).to eql('IS NOT NULL')
    end

    it 'is case insensitive' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'familyName eQ BAZ'
      )

      expect(instance.operator()).to eql('=')
    end
  end # "context '#operator' do"

  # ===========================================================================
  # PARAMETERS
  # ===========================================================================

  context '#parameter' do
    it 'returns a blank string if a parameter is missing' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'familyName eq'
      )

      expect(instance.parameter()).to eql('')
    end

    it 'returns the parameter if present' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'familyName eq BAZ'
      )

      expect(instance.parameter()).to eql('BAZ')
    end
  end # "context '#parameter' do"

  # ===========================================================================
  # ACTIVERECORD QUERIES
  # ===========================================================================

  context '#to_activerecord_query' do
    it 'generates expected SQL' do

      # Hand-written instead of using a constant, so we check one set of hand
      # drawn mappings against another and hopefully increase the chances of
      # spotting an error.
      #
      expected_mapping = {
        'eq' => '=',
        'ne' => '!=',
        'gt' => '>',
        'ge' => '>=',
        'lt' => '<',
        'le' => '<=',
        'co' => 'LIKE',
        'sw' => 'LIKE',
        'ew' => 'LIKE'
      }

      # Self-check: Is test coverage up to date?
      #
      expect(expected_mapping.keys).to match_array(Scimitar::Lists::QueryParser::SQL_COMPARISON_OPERATOR.keys)

      expected_mapping.each do | input, expected_output |
        instance = described_class.new(
          MockUser.new.scim_queryable_attributes(),
          "familyName #{input} BAZ"
        )




      end
    end

    xit 'handles "pr" (presence) checks' do
    end

    xit 'escapes values sent into LIKE statements' do
    end
  end # "context '#to_activerecord_query' do"
end
