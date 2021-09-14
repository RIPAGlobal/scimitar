require 'active_support/hash_with_indifferent_access'

class Hash
  def with_indifferent_case_insensitive_access
    Scimitar::Support::HashWithIndifferentCaseInsensitiveAccess.new(self)
  end
end

module Scimitar
  module Support

    # A subclass of ActiveSupport::HashWithIndifferentAccess where not only
    # can Hash keys be queried as Symbols or Strings, but they are looked up
    # in a case-insensitive fashion too.
    #
    # During enumeration, Hash keys will always be returned in whatever case
    # they were originally set.
    #
    class HashWithIndifferentCaseInsensitiveAccess < ActiveSupport::HashWithIndifferentAccess
      def with_indifferent_case_insensitive_access
        self
      end

      private

        if Symbol.method_defined?(:name)
          def convert_key(key)
            key.kind_of?(Symbol) ? key.name.downcase : key.downcase
          end
        else
          def convert_key(key)
            key.kind_of?(Symbol) ? key.to_s.downcase : key.downcase
          end
        end

        def update_with_single_argument(other_hash, block)
          if other_hash.is_a? HashWithIndifferentCaseInsensitiveAccess
            regular_update(other_hash, &block)
          else
            other_hash.to_hash.each_pair do |key, value|
              if block && key?(key)
                value = block.call(convert_key(key), self[key], value)
              end
              regular_writer(convert_key(key), convert_value(value))
            end
          end
        end

    end
  end
end
