module Scimitar
  module Lists

    # Simple SCIM filter support.
    #
    # This is currently an extremely limited query parser supporting only a
    # single "name-operator-value" query, no boolean operations or precedence
    # operators and it assumes "LIKE" and "%" as wildcards in SQL for any
    # operators which require partial match (contains / "co", starts with /
    # "sw", ends with / "ew"). Generic operations don't support "pr" either
    # ('presence').
    #
    # TODO: Be less, eeeh, well - frankly - lame.
    #
    # Create an instance, then construct a query appropriate for your storage
    # back-end using #attribute to get the attribute name (in terms of "your
    # data", via your Scimitar::Resources::Mixin-including class implementation
    # of ::scim_queryable_attributes), #operator to get a generic SQL operator
    # such as "=" or "!=" and #parameter to get the value to be found (which
    # you MUST take care to process so as to avoid an SQL injection or similar
    # issues - use escaping suitable for your storage system's query language).
    #
    # * If you don't want to support LIKE just check for it in #parameter's
    #   return value; it'll be upper case.
    #
    # Given the likelihood of using ActiveRecord via Rails, there's a higher
    # level and easier method - just create the instance, then call
    # QueryParser#to_activerecord_query to get a given base scope narrowed down
    # to match the filter parameters.
    #
    class QueryParser

      # Map SCIM operators to generic(ish) SQL operators. See #operator.
      #
      SQL_COMPARISON_OPERATOR = {
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

      attr_reader :query_elements
      attr_reader :attribute_map

      # Initialise an object.
      #
      # +attribute_map+:: See Scimitar::Resources::Mixin and documentation on
      #                   implementing ::scim_queryable_attributes; pass that
      #                   method's return value here.
      #
      # +query_string+::  Query string from inbound HTTP request.
      #
      def initialize(attribute_map, query_string)
        @attribute_map  = attribute_map
        @query_elements = query_string.split(" ")
      end

      # Returns the mapped-to-your-domain attribute that the filter string is
      # operating upon. If +nil+, there is no match.
      #
      # TODO: Support more than one filter entry!
      #
      def attribute
        attribute = self.query_elements()[0]

        raise Scimitar::FilterError if attribute.blank?

        attribute = attribute.to_sym
        mapped    = self.attribute_map()[attribute]

        raise Scimitar::FilterError if mapped.blank?

        return mapped
      end

      # Returns an SQL operator equivalent to that given in the filter string.
      #
      # Raises Scimitar::FilterError if the filter cannot be
      # handled. The most likely case is for "pr" (presence), which has no
      # simple generic (ish) SQL equivalent. Note that "LIKE" is returned for
      # "co", "sw" and "ew" (contains, starts-with, ends-with).
      #
      # TODO: Support more than one filter entry!
      #
      def operator
        scim_operator = self.query_elements()[1]

        raise Scimitar::FilterError if scim_operator.nil?

        sql_operator = if scim_operator.downcase == 'pr'
          'IS NOT NULL'
        else
          self.sql_comparison_operator(scim_operator) || (raise Scimitar::FilterError)
        end

        return sql_operator
      end

      # Return the parameter that you're looking for, from the filter string.
      # This might be blank, e.g. for "pr" (presence), but is never +nil+. Use
      # this to construct your storage-system-specific search string but be
      # sure to escape it, where necessary, for any special characters (e.g.
      # to prevent SQL injection attacks or accidentally-wildcarded searches).
      #
      # TODO: Support more than one filter entry!
      #
      def parameter
        parameter = self.query_elements()[2..-1].join(" ")
        return parameter.blank? ? '' : parameter
      end

      # Collates #attribute, #operator and #parameter into an ActiveRecord
      # query that also handles "pr" (presence) checks. Asssumes "%" is a valid
      # wildcard for the LIKE operator. Handles all safety/escaping issues.
      # Returns an ActiveRecord::Relation that narrows the given base scope.
      #
      # +base_scope+:: ActiveRecord::Relation that is to be narrowed by filter
      #                (e.g. "User.all" or "Company.users").
      #
      def to_activerecord_query(base_scope)
        safe_column_name = ActiveRecord::Base.connection.quote_column_name(self.attribute())
        safe_value       = sql_modified_value(self.operator(), self.parameter())
        query            = base_scope

        if safe_value.nil? && operator.nil? # Presence ("pr") assumed
          query = query.where.not(safe_column_name => ['', nil])
        elsif safe_value.present? && operator.present? # Everything else
          query = query.where("\"#{safe_column_name}\" #{operator} (?)", safe_value)
        else
          raise Scimitar::FilterError
        end

        return query
      end

      private

        # TODO: implement and/or/not
        # TODO: implement additional operators?
        #
        # https://tools.ietf.org/html/rfc7644#section-3.4.2.2
        #
        # Translates a SCIM test operator into a generic (ish, given "LIKE" is
        # included here) SQL operator. Returns it.
        #
        # If there's no equivalent in generic SQL, returns +nil+.
        #
        # +element+:: The SCIM operator. It can be upper/lower/mixed case.
        #             For example - "gE" (greater than or equal to).
        #
        def sql_comparison_operator(element)
          SQL_COMPARISON_OPERATOR[element&.downcase]
        end

        # Takes a parameter value from a SCIM filter string and the filter
        # operation (e.g. "ge", greater than or equal to). Translates the value
        # into a "safe for LIKE expressions" value that might include wildcards
        # or, for "presence", will be returned as +nil+ - note, not blank, as
        # would be returned by #parameter.
        #
        # +element+:: The SCIM operator. It can be upper/lower/mixed case.
        #             For example - "gE" (greater than or equal to).
        #
        # +value+::   The value to translate. Might be returned as-is, or have
        #             special characters escaped and wildcards added; or even
        #             be ignored for "pr" (presence) checks.
        #
        def sql_modified_value(element, value)
          safe_for_LIKE_value = ActiveRecord::Base.sanitize_sql_like(value)

          case element&.downcase
            when 'co'
              "%#{safe_for_LIKE_value}%"
            when 'sw'
              "#{safe_for_LIKE_value}%"
            when 'ew'
              "%#{safe_for_LIKE_value}"
            when 'pr'
              nil
            else
              value
          end
        end
    end
  end
end
