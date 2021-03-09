require 'spec_helper'

# Note that #

RSpec.describe Scimitar::Lists::QueryParser do

  # We use the dummy app's MockUser class, so need a database connection from
  # that app too. ActiveRecord can then escape column values, generate SQL and
  # so-forth, and we can run tests to check on that output to verify that
  # the gem has instructed ActiveRecord appropriately.
  #
  require_relative '../../../apps/dummy/app/models/mock_user.rb'

  before :each do
    @instance = described_class.new(MockUser.new.scim_queryable_attributes())
  end

  # ===========================================================================
  # PRIVATE METHODS
  # ===========================================================================

  context 'internal method' do

    # =========================================================================
    # Attributes
    # =========================================================================

    context '#activerecord_attribute' do
      it 'complains if there is no attribute present' do
        expect { @instance.send(:activerecord_attribute, nil) }.to raise_error(Scimitar::FilterError)
        expect { @instance.send(:activerecord_attribute, '' ) }.to raise_error(Scimitar::FilterError)
      end

      it 'complains if there is no attribute mapping available' do
        expect { @instance.send(:activerecord_attribute, 'externalId') }.to raise_error(Scimitar::FilterError)
      end

      it 'returns the attribute' do
        expect(@instance.send(:activerecord_attribute, 'familyName')).to eql(:last_name)
      end
    end # "context '#activerecord_attribute' do"

    # =========================================================================
    # Operators
    # =========================================================================

    context '#activerecord_operator' do
      it 'complains if there is no operator present' do
        expect { @instance.send(:activerecord_operator, nil) }.to raise_error(Scimitar::FilterError)
        expect { @instance.send(:activerecord_operator, '' ) }.to raise_error(Scimitar::FilterError)
      end

      it 'complains if the operator is unrecognised' do
        @instance = described_class.new(MockUser.new.scim_queryable_attributes())

        expect { @instance.send(:activerecord_operator, 'zz') }.to raise_error(Scimitar::FilterError)
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
        expect(expected_mapping.keys).to match_array(Scimitar::Lists::QueryParser::SQL_COMPARISON_OPERATORS.keys)

        expected_mapping.each do | input, expected_output |
          expect(@instance.send(:activerecord_operator, input)).to eql(expected_output)
        end
      end

      it 'is case insensitive' do
        expect(@instance.send(:activerecord_operator, 'eQ')).to eql('=')
      end
    end # "context '#activerecord_operator' do"

    # =========================================================================
    # Parameters
    # =========================================================================

    context '#activerecord_parameter' do
      it 'returns a blank string if a parameter is missing' do
        expect(@instance.send(:activerecord_parameter, nil )).to eql('')
        expect(@instance.send(:activerecord_parameter, ''  )).to eql('')
        expect(@instance.send(:activerecord_parameter, '  ')).to eql('')
      end

      it 'returns the parameter if present' do
        expect(@instance.send(:activerecord_parameter, 'BAZ')).to eql('BAZ')
      end

      it 'removes surrounding quotes if present' do
        expect(@instance.send(:activerecord_parameter, '"BA"Z"')).to eql('BA"Z')
        expect(@instance.send(:activerecord_parameter, '"BA"Z' )).to eql('"BA"Z')
        expect(@instance.send(:activerecord_parameter, 'BA"Z"' )).to eql('BA"Z"')
      end
    end # "context '#parameter' do"
  end # "context 'unit tests for internal methods' do"

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
        'eQ' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" = 'BAZ')},
        'Ne' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" != 'BAZ')},
        'GT' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" > 'BAZ')},
        'ge' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" >= 'BAZ')},
        'LT' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" < 'BAZ')},
        'Le' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" <= 'BAZ')},
        'cO' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" LIKE '%BAZ%')},
        'sw' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" LIKE 'BAZ%')},
        'eW' => %q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" LIKE '%BAZ')},
      }

      # Self-check: Is test coverage up to date?
      #
      expect(expected_mapping.keys.map(&:downcase)).to match_array(Scimitar::Lists::QueryParser::SQL_COMPARISON_OPERATORS.keys)

      expected_mapping.each do | input, expected_output |
        @instance.parse("familyName #{input} \"BAZ\"")
        query = @instance.to_activerecord_query(MockUser.all)

        # Run a count just to prove the result is at least of valid syntax and
        # check the SQL against expectations.
        #
        expect { query.count }.to_not raise_error
        expect(query.to_sql).to eql(expected_output)
      end
    end

    it 'handles "pr" (presence) checks' do
      @instance.parse("familyName Pr")
      query = @instance.to_activerecord_query(MockUser.all)

      # NB ActiveRecord SQL quirk leads to double parentheses after the WHERE
      # NOT clause; this is harmless.
      #
      expect(query.to_sql).to eql(%q{SELECT "mock_users".* FROM "mock_users" WHERE NOT (("mock_users"."last_name" = '' OR "mock_users"."last_name" IS NULL))})
    end

    # Technically tests #parse :-) but I hit this when writing the test that
    # immediately follows - this location will do for now, since OK in context.
    #
    it 'complains about incorrectly quoted queries' do
      expect { @instance.parse('familyName co B%_AZ') }.to raise_error(Scimitar::FilterError)
    end

    it 'escapes values sent into LIKE statements' do
      @instance.parse('familyName co "B%_AZ"')
      query = @instance.to_activerecord_query(MockUser.all)

      expect(query.to_sql).to eql(%q{SELECT "mock_users".* FROM "mock_users" WHERE ("last_name" LIKE '%B\%\_AZ%')})
    end

    it 'operates correctly with a few hand-chosen basic queries' do
      user_1 = MockUser.create(first_name: 'Jane', last_name: 'Doe')
      user_2 = MockUser.create(first_name: 'John', last_name: 'Smithe')
      user_3 = MockUser.create(                    last_name: 'Davis')

      # Test the various "LIKE" wildcards

      @instance.parse('familyName co o') # Last name contains 'o'
      query = @instance.to_activerecord_query(MockUser.all)

      expect(query.count).to eql(1)
      expect(query.pluck(:id)).to eql([user_1.id])

      @instance.parse('givenName sw J') # First name starts with 'J'
      query = @instance.to_activerecord_query(MockUser.all)

      expect(query.count).to eql(2)
      expect(query.pluck(:id)).to match_array([user_1.id, user_2.id])

      @instance.parse('familyName ew he') # Last name ends with 'he'
      query = @instance.to_activerecord_query(MockUser.all)

      expect(query.count).to eql(1)
      expect(query.pluck(:id)).to eql([user_2.id])

      # Test presence

      @instance.parse('givenName pr') # First name is present
      query = @instance.to_activerecord_query(MockUser.all)

      expect(query.count).to eql(2)
      expect(query.pluck(:id)).to match_array([user_1.id, user_2.id])

      # Test a simple not-equals, but use a custom starting scope. Note that
      # the query would find "user_3" *except* there is no first name defined
      # at all, and in SQL, "foo != bar" is *not* a match if foo IS NULL.

      @instance.parse('givenName ne Bob') # First name is not 'Bob'
      query = @instance.to_activerecord_query(MockUser.where.not('first_name' => 'John'))

      expect(query.count).to eql(1)
      expect(query.pluck(:id)).to match_array([user_1.id])
    end

    context 'with complex cases' do
      context 'using AND' do
        it 'generates expected SQL' do
          @instance.parse('givenName pr AND familyName eq "Doe"')
          query = @instance.to_activerecord_query(MockUser.all)

          expect(query.to_sql).to eql(%q{SELECT "mock_users".* FROM "mock_users" WHERE NOT (("mock_users"."first_name" = '' OR "mock_users"."first_name" IS NULL)) AND ("last_name" = 'Doe')})
        end

        it 'finds expected items' do
          user_1 = MockUser.create(first_name: 'Jane', last_name: 'Davis')
          user_2 = MockUser.create(first_name: 'John', last_name: 'Doe')
          user_3 = MockUser.create(                    last_name: 'Doe')

          @instance.parse('givenName pr AND familyName eq "Doe"')
          query = @instance.to_activerecord_query(MockUser.all)

          expect(query.count).to eql(1)
          expect(query.pluck(:id)).to match_array([user_2.id])
        end
      end # "context 'simple AND' do"

      context 'using OR' do
        it 'generates expected SQL' do
          @instance.parse('givenName pr OR familyName eq "Doe"')
          query = @instance.to_activerecord_query(MockUser.all)

          expect(query.to_sql).to eql(%q{SELECT "mock_users".* FROM "mock_users" WHERE (NOT (("mock_users"."first_name" = '' OR "mock_users"."first_name" IS NULL)) OR "last_name" = 'Doe')})
        end

        it 'finds expected items' do
          user_1 = MockUser.create(first_name: 'Jane', last_name: 'Davis')
          user_2 = MockUser.create(                    last_name: 'Doe')
          user_3 = MockUser.create(                    last_name: 'Smith')

          @instance.parse('givenName pr OR familyName eq "Doe"')
          query = @instance.to_activerecord_query(MockUser.all)

          expect(query.count).to eql(2)
          expect(query.pluck(:id)).to match_array([user_1.id, user_2.id])
        end
      end # "context 'simple OR' do"

      context 'combined AND, OR and parentheses' do
        it 'generates expected SQL' do
          @instance.parse('givenName eq "Jane" and (familyName co "avi" or familyName ew "ith")')
          query = @instance.to_activerecord_query(MockUser.all)

          expect(query.to_sql).to eql(%q{SELECT "mock_users".* FROM "mock_users" WHERE ("first_name" = 'Jane') AND ("last_name" LIKE '%avi%' OR "last_name" LIKE '%ith')})
        end

        it 'finds expected items' do
          user_1 = MockUser.create(first_name: 'Jane', last_name: 'Davis')   # Match
          user_2 = MockUser.create(first_name: 'Jane', last_name: 'Smith')   # Match
          user_3 = MockUser.create(first_name: 'Jane', last_name: 'Moreith') # Match
          user_4 = MockUser.create(first_name: 'Jane', last_name: 'Doe')     # No last name match
          user_5 = MockUser.create(first_name: 'Doe',  last_name: 'Smith')   # No first name match
          user_6 = MockUser.create(first_name: 'Bill', last_name: 'Davis')   # No first name match
          user_7 = MockUser.create(                    last_name: 'Davis')   # Missing first name
          user_8 = MockUser.create(                    last_name: 'Smith')   # Missing first name

          @instance.parse('givenName eq "Jane" and (familyName co "avi" or familyName ew "ith")')
          query = @instance.to_activerecord_query(MockUser.all)

          expect(query.count).to eql(3)
          expect(query.pluck(:id)).to match_array([user_1.id, user_2.id, user_3.id])
        end
      end # "context 'combined AND and OR' do"
    end # "context 'complex cases' do"
  end # "context '#to_activerecord_query' do"
end # "RSpec.describe Scimitar::Lists::QueryParser do"
