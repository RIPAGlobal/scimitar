require 'active_support/hash_with_indifferent_access'

class Hash

  # Converts this Hash to an instance of
  # Scimitar::Support::HashWithIndifferentCaseInsensitiveAccess, which is
  # a subclass of ActiveSupport::HashWithIndifferentAccess with the addition of
  # case-insensitive lookup.
  #
  # Note that this is more thorough than the ActiveSupport counterpart. It
  # converts recursively, so that all Hashes to arbitrary depth, including any
  # hashes inside Arrays, are converted. This is an expensive operation.
  #
  def with_indifferent_case_insensitive_access
    self.class.deep_indifferent_case_insensitive_access(self)
  end

  # Supports #with_indifferent_case_insensitive_access. Converts the given item
  # to indifferent, case-insensitive access as a Hash; or converts Array items
  # if given an Array; or returns the given object.
  #
  # Hashes and Arrays at all depths are duplicated as a result.
  #
  def self.deep_indifferent_case_insensitive_access(object)
    if object.is_a?(Hash)
      new_hash = Scimitar::Support::HashWithIndifferentCaseInsensitiveAccess.new(object)
      new_hash.each do | key, value |
        new_hash[key] = deep_indifferent_case_insensitive_access(value)
      end
      new_hash

    elsif object.is_a?(Array)
      object.map do | array_entry |
        deep_indifferent_case_insensitive_access(array_entry)
      end

    else
      object

    end
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
