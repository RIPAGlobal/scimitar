require 'spec_helper'

# Note that #

RSpec.describe Scimitar::Lists::QueryParser do

  # We use the dummy app's MockUser class, so need a database connection from
  # that app too. ActiveRecord can then escape column values, generate SQL and
  # so-forth, and we can run tests to check on that output to verify that
  # the gem has instructed ActiveRecord appropriately.
  #
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
        'eq' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" = 'BAZ')},
        'ne' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" != 'BAZ')},
        'gt' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" > 'BAZ')},
        'ge' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" >= 'BAZ')},
        'lt' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" < 'BAZ')},
        'le' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" <= 'BAZ')},
        'co' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" LIKE '%BAZ%')},
        'sw' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" LIKE 'BAZ%')},
        'ew' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" LIKE '%BAZ')},
      }

      # Self-check: Is test coverage up to date?
      #
      expect(expected_mapping.keys).to match_array(Scimitar::Lists::QueryParser::SQL_COMPARISON_OPERATOR.keys)

      expected_mapping.each do | input, expected_output |
        instance = described_class.new(
          MockUser.new.scim_queryable_attributes(),
          "familyName #{input} BAZ"
        )

        query = instance.to_activerecord_query(MockUser.all)

        # Run a count just to prove the result is at least of valid syntax and
        # check the SQL against expectations.
        #
        expect { query.count }.to_not raise_error
        expect(query.to_sql).to eql(expected_output)
      end
    end

    it 'handles "pr" (presence) checks' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'familyName pr'
      )

      # NB ActiveRecord SQL quirk leads to double parentheses after the WHERE
      # NOT clause; this is harmless.
      #
      query = instance.to_activerecord_query(MockUser.all)
      expect(query.to_sql).to eql(%q{SELECT "mock_users".* FROM "mock_users" WHERE NOT (("mock_users"."last_name" = '' OR "mock_users"."last_name" IS NULL))})
    end

    it 'escapes values sent into LIKE statements' do
      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'familyName co B%_AZ'
      )

      query = instance.to_activerecord_query(MockUser.all)
      expect(query.to_sql).to eql(%q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" LIKE '%B\%\_AZ%')})
    end

    it 'operates correctly with a few hand-chosen basic queries' do
      user_1 = MockUser.create(first_name: 'Jane', last_name: 'Doe')
      user_2 = MockUser.create(first_name: 'John', last_name: 'Smithe')
      user_3 = MockUser.create(                    last_name: 'Davis')

      # Test the various "LIKE" wildcards

      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'familyName co o' # Last name contains 'o'
      )

      query = instance.to_activerecord_query(MockUser.all)
      expect(query.count).to eql(1)
      expect(query.pluck(:id)).to eql([user_1.id])

      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'givenName sw J' # First name starts with 'J'
      )

      query = instance.to_activerecord_query(MockUser.all)
      expect(query.count).to eql(2)
      expect(query.pluck(:id)).to match_array([user_1.id, user_2.id])

      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'familyName ew he' # Last name ends with 'he'
      )

      query = instance.to_activerecord_query(MockUser.all)
      expect(query.count).to eql(1)
      expect(query.pluck(:id)).to eql([user_2.id])

      # Test presence

      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'givenName pr' # First name is present
      )

      query = instance.to_activerecord_query(MockUser.all)
      expect(query.count).to eql(2)
      expect(query.pluck(:id)).to match_array([user_1.id, user_2.id])

      # Test a simple not-equals, but use a custom starting scope. Note that
      # the query would find "user_3" *except* there is no first name defined
      # at all, and in SQL, "foo != bar" is *not* a match if foo IS NULL.

      instance = described_class.new(
        MockUser.new.scim_queryable_attributes(),
        'givenName ne Bob' # First name is not 'Bob'
      )

      query = instance.to_activerecord_query(MockUser.where.not('first_name' => 'John'))

      expect(query.count).to eql(1)
      expect(query.pluck(:id)).to match_array([user_1.id])
    end
  end # "context '#to_activerecord_query' do"

  # ===========================================================================
  # INSTANTIATION
  # ===========================================================================

  context 'instantiation' do
    it 'complains if not given a String for the query, which can in particular happen if "params" is handled improperly in the controller' do
      expect {
        described_class.new(
          MockUser.new.scim_queryable_attributes(),
          {'filter' => 'familyName eq BAZ'}
        )
      }.to raise_error(RuntimeError, /#{Regexp.escape('Hash passed')}/)
    end
  end # "context 'instantiation' do"
end
