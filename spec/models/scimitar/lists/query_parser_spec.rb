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
  # BASIC PARSING
  #
  # Adapted from SCIM Query Filter Parser's non-RSpec tests.
  # ===========================================================================

  context 'basic parsing' do
    it "empty string" do
      @instance.parse("")

      rpn = @instance.rpn
      expect(rpn).to be_empty

      tree = @instance.tree
      expect(tree).to be_empty
    end

    it "user name equals" do
      @instance.parse(%Q(userName eq "bjensen"))

      rpn = @instance.rpn
      expect('userName').to eql(rpn[0])
      expect('"bjensen"').to eql(rpn[1])
      expect('eq').to eql(rpn[2])

      tree = @instance.tree
      expect('eq').to eql(tree[0])
      expect('userName').to eql(tree[1])
      expect('"bjensen"').to eql(tree[2])
    end

    it "family name equals" do
      @instance.parse(%Q(name.familyName co "O'Malley"))

      rpn = @instance.rpn
      expect('name.familyName').to eql(rpn[0])
      expect(%Q("O'Malley")).to eql(rpn[1])
      expect('co').to eql(rpn[2])

      tree = @instance.tree
      expect('co').to eql(tree[0])
      expect('name.familyName').to eql(tree[1])
      expect(%Q("O'Malley")).to eql(tree[2])
    end

    it "user name starts with" do
      @instance.parse(%Q(userName sw "J"))

      rpn = @instance.rpn
      expect('userName').to eql(rpn[0])
      expect(%Q("J")).to eql(rpn[1])
      expect('sw').to eql(rpn[2])

      tree = @instance.tree
      expect('sw').to eql(tree[0])
      expect('userName').to eql(tree[1])
      expect('"J"').to eql(tree[2])
    end

    it "title present" do
      @instance.parse(%Q(title pr))

      rpn = @instance.rpn
      expect('title').to eql(rpn[0])
      expect('pr').to eql(rpn[1])

      tree = @instance.tree
      expect('pr').to eql(tree[0])
      expect('title').to eql(tree[1])
    end

    it "last modified greater than" do
      @instance.parse(%Q(meta.lastModified gt "2011-05-13T04:42:34Z"))

      rpn = @instance.rpn
      expect('meta.lastModified').to eql(rpn[0])
      expect('"2011-05-13T04:42:34Z"').to eql(rpn[1])
      expect('gt').to eql(rpn[2])

      tree = @instance.tree
      expect('gt').to eql(tree[0])
      expect('meta.lastModified').to eql(tree[1])
      expect('"2011-05-13T04:42:34Z"').to eql(tree[2])
    end

    it "last modified greater than or equal to" do
      @instance.parse(%Q(meta.lastModified ge "2011-05-13T04:42:34Z"))

      rpn = @instance.rpn

      expect('meta.lastModified').to eql(rpn[0])
      expect('"2011-05-13T04:42:34Z"').to eql(rpn[1])
      expect('ge').to eql(rpn[2])

      tree = @instance.tree
      expect('ge').to eql(tree[0])
      expect('meta.lastModified').to eql(tree[1])
      expect('"2011-05-13T04:42:34Z"').to eql(tree[2])
    end

    it "last modified less than" do
      @instance.parse(%Q(meta.lastModified lt "2011-05-13T04:42:34Z"))

      rpn = @instance.rpn

      expect('meta.lastModified').to eql(rpn[0])
      expect('"2011-05-13T04:42:34Z"').to eql(rpn[1])
      expect('lt').to eql(rpn[2])

      tree = @instance.tree
      expect('lt').to eql(tree[0])
      expect('meta.lastModified').to eql(tree[1])
      expect('"2011-05-13T04:42:34Z"').to eql(tree[2])
    end

    it "last modified less than or equal to" do
      @instance.parse(%Q(meta.lastModified le "2011-05-13T04:42:34Z"))

      rpn = @instance.rpn

      expect('meta.lastModified').to eql(rpn[0])
      expect('"2011-05-13T04:42:34Z"').to eql(rpn[1])
      expect('le').to eql(rpn[2])

      tree = @instance.tree
      expect('le').to eql(tree[0])
      expect('meta.lastModified').to eql(tree[1])
      expect('"2011-05-13T04:42:34Z"').to eql(tree[2])
    end

    it "title and user type equal" do
      @instance.parse(%Q(title pr and userType eq "Employee"))

      rpn = @instance.rpn

      expect('title').to eql(rpn[0])
      expect('pr').to eql(rpn[1])
      expect('userType').to eql(rpn[2])
      expect('"Employee"').to eql(rpn[3])
      expect('eq').to eql(rpn[4])
      expect('and').to eql(rpn[5])

      tree = @instance.tree
      expect(3).to eql(tree.count)
      expect('and').to eql(tree[0])

      sub = tree[1]
      expect(2).to eql(sub.count)
      expect('pr').to eql(sub[0])
      expect('title').to eql(sub[1])

      sub = tree[2]
      expect(3).to eql(sub.count)
      expect('eq').to eql(sub[0])
      expect('userType').to eql(sub[1])
      expect('"Employee"').to eql(sub[2])
    end

    it "title or user type equal" do
      @instance.parse(%Q(title pr or userType eq "Intern"))

      rpn = @instance.rpn

      expect('title').to eql(rpn[0])
      expect('pr').to eql(rpn[1])
      expect('userType').to eql(rpn[2])
      expect('"Intern"').to eql(rpn[3])
      expect('eq').to eql(rpn[4])
      expect('or').to eql(rpn[5])

      tree = @instance.tree
      expect(3).to eql(tree.count)
      expect('or').to eql(tree[0])

      sub = tree[1]
      expect(2).to eql(sub.count)
      expect('pr').to eql(sub[0])
      expect('title').to eql(sub[1])

      sub = tree[2]
      expect(3).to eql(sub.count)
      expect('eq').to eql(sub[0])
      expect('userType').to eql(sub[1])
      expect('"Intern"').to eql(sub[2])
    end

    it "compound filter" do
      @instance.parse(%Q{userType eq "Employee" and (emails co "example.com" or emails co "example.org")})

      rpn = @instance.rpn

      expect('userType').to eql(rpn[0])
      expect('"Employee"').to eql(rpn[1])
      expect('eq').to eql(rpn[2])
      expect('emails').to eql(rpn[3])
      expect('"example.com"').to eql(rpn[4])
      expect('co').to eql(rpn[5])
      expect('emails').to eql(rpn[6])
      expect('"example.org"').to eql(rpn[7])
      expect('co').to eql(rpn[8])
      expect('or').to eql(rpn[9])
      expect('and').to eql(rpn[10])

      tree = @instance.tree
      expect(3).to eql(tree.count)
      expect('and').to eql(tree[0])

      sub = tree[1]
      expect(3).to eql(sub.count)
      expect('eq').to eql(sub[0])
      expect('userType').to eql(sub[1])
      expect('"Employee"').to eql(sub[2])

      sub = tree[2]
      expect(3).to eql(sub.count)
      expect('or').to eql(sub[0])

      expect(3).to eql(sub[1].count)
      expect('co').to eql(sub[1][0])
      expect('emails').to eql(sub[1][1])
      expect('"example.com"').to eql(sub[1][2])

      expect(3).to eql(sub[2].count)
      expect('co').to eql(sub[2][0])
      expect('emails').to eql(sub[2][1])
      expect('"example.org"').to eql(sub[2][2])
    end
  end # "context 'basic parsing' do"

  # ===========================================================================
  # INTERNAL FILTER FLATTENING
  #
  # Attempts to reduce query parser complexity while tolerating a wider range
  # of input "styles" of filter
  # ===========================================================================

  context '#flatten_filter (private)' do
    it 'flattens simple cases' do
      result = @instance.send(:flatten_filter, 'userType eq "Employee" and emails[type eq "work" and value co "@example.com"]')
      expect(result).to eql('userType eq "Employee" and emails.type eq "work" and emails.value co "@example.com"')
    end

    it 'correctly processes more than one inner filter' do
      result = @instance.send(:flatten_filter, 'emails[type eq "work" and value co "@example.com"] or userType eq "Admin" or ims[type eq "xmpp" and value co "@foo.com"]')
      expect(result).to eql('emails.type eq "work" and emails.value co "@example.com" or userType eq "Admin" or ims.type eq "xmpp" and ims.value co "@foo.com"')
    end

    it 'flattens nested cases' do
      result = @instance.send(:flatten_filter, 'userType ne "Employee" and not (emails[value co "example.com" or (value co "example.org")]) and userName="foo"')
      expect(result).to eql('userType ne "Employee" and not (emails.value co "example.com" or (emails.value co "example.org")) and userName="foo"')
    end

    it 'handles spaces in quoted values' do
      result = @instance.send(:flatten_filter, 'userType eq "Employee spaces" or userName pr and emails[type eq "with spaces" and value co "@example.com"]')
      expect(result).to eql('userType eq "Employee spaces" or userName pr and emails.type eq "with spaces" and emails.value co "@example.com"')
    end

    it 'handles escaped quotes in quoted values' do
      result = @instance.send(:flatten_filter, 'userType eq "Emplo\\"yee" and emails[type eq "\\"work\\"" and value co "@example.com"]')
      expect(result).to eql('userType eq "Emplo\\"yee" and emails.type eq "\\"work\\"" and emails.value co "@example.com"')
    end

    it 'handles escaped opening square brackets' do
      result = @instance.send(:flatten_filter, 'userType eq \\[Employee and emails[type eq "work" and value co "@example.com"]')
      expect(result).to eql('userType eq \\[Employee and emails.type eq "work" and emails.value co "@example.com"')
    end

    it 'handles escaped closing square brackets' do
      result = @instance.send(:flatten_filter, 'userType eq "Employee" and emails[type eq "work" and value co Unquoted\\]]')
      expect(result).to eql('userType eq "Employee" and emails.type eq "work" and emails.value co Unquoted\\]')
    end

    it 'handles spaces before closing square brackets' do
      result = @instance.send(:flatten_filter, 'emails[type eq "work" and value co "@example.com"    ] or userType eq "Admin" or ims[type eq "xmpp" and value co "@foo.com"]')
      expect(result).to eql('emails.type eq "work" and emails.value co "@example.com" or userType eq "Admin" or ims.type eq "xmpp" and ims.value co "@foo.com"')
    end
  end # "context '#flatten_filter (private)' do"

  # ===========================================================================
  # ACTIVERECORD QUERIES
  #
  # If you have issues here, check that private method unit tests are passing
  # before worrying about these higher-level checks.
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
end # "RSpec.describe Scimitar::Lists::QueryParser do"
