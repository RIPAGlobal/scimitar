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
      new_hash = Scimitar::Support::HashWithIndifferentCaseInsensitiveAccess.new
      object.each do | key, value |
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
    # they were originally set. Just as with
    # ActiveSupport::HashWithIndifferentAccess, though, the type of the keys is
    # always returned as a String, even if originally set as a Symbol - only
    # the upper/lower case nature of the original key is preserved.
    #
    # If a key is written more than once with the same effective meaning in a
    # to-string, to-downcase form, then whatever case was used *first* wins;
    # e.g. if you did hash['User'] = 23, then hash['USER'] = 42, the result
    # would be {"User" => 42}.
    #
    class HashWithIndifferentCaseInsensitiveAccess < ActiveSupport::HashWithIndifferentAccess
      def with_indifferent_case_insensitive_access
        self
      end

      def initialize(constructor = nil)
        @scimitar_hash_with_indifferent_case_insensitive_access_key_map = {}
        super
      end

      # It's vital that the attribute map is carried over when one of these
      # objects is duplicated. Duplication of this ivar state does *not* happen
      # when 'dup' is called on our superclass, so we have to do that manually.
      #
      def dup
        duplicate = super
        duplicate.instance_variable_set(
          '@scimitar_hash_with_indifferent_case_insensitive_access_key_map',
          @scimitar_hash_with_indifferent_case_insensitive_access_key_map
        )
      end

      # Override the individual key writer.
      #
      def []=(key, value)

        string_key      = scimitar_hash_with_indifferent_case_insensitive_access_string(key)
        indifferent_key = scimitar_hash_with_indifferent_case_insensitive_access_downcase(string_key)
        converted_value = convert_value(value, conversion: :assignment)

        # Note '||=', as there might have been a prior use of the "same" key in
        # a different case. The earliest one is preserved since the actual Hash
        # underneath all this is already using that variant of the key.
        #
        key_for_writing = (
          @scimitar_hash_with_indifferent_case_insensitive_access_key_map[indifferent_key] ||= string_key
        )

        regular_writer(key_for_writing, converted_value)
      end

      # Override #merge to express it in terms of #merge! (also overridden), so
      # that merged hashes can have their keys treated indifferently too.
      #
      def merge(*other_hashes, &block)
        dup.merge!(*other_hashes, &block)
      end

      # Modifies-self version of #merge, overriding Hash#merge!.
      #
      def merge!(*hashes_to_merge_to_self, &block)
        if block_given?
          hashes_to_merge_to_self.each do |hash_to_merge_to_self|
            hash_to_merge_to_self.each_pair do |key, value|
              value = block.call(key, self[key], value) if self.key?(key)
              self[key] = value
            end
          end
        else
          hashes_to_merge_to_self.each do |hash_to_merge_to_self|
            hash_to_merge_to_self.each_pair do |key, value|
              self[key] = value
            end
          end
        end

        self
      end

      # =======================================================================
      # PRIVATE INSTANCE METHODS
      # =======================================================================
      #
      private

        if Symbol.method_defined?(:name)
          def scimitar_hash_with_indifferent_case_insensitive_access_string(key)
            key.kind_of?(Symbol) ? key.name : key
          end
        else
          def scimitar_hash_with_indifferent_case_insensitive_access_string(key)
            key.kind_of?(Symbol) ? key.to_s : key
          end
        end

        def scimitar_hash_with_indifferent_case_insensitive_access_downcase(key)
          key.kind_of?(String) ? key.downcase : key
        end

        def convert_key(key)
          string_key      = scimitar_hash_with_indifferent_case_insensitive_access_string(key)
          indifferent_key = scimitar_hash_with_indifferent_case_insensitive_access_downcase(string_key)

          @scimitar_hash_with_indifferent_case_insensitive_access_key_map[indifferent_key] || string_key
        end

        def convert_value(value, conversion: nil)
          if value.is_a?(Hash)
            if conversion == :to_hash
              value.to_hash
            else
              value.with_indifferent_case_insensitive_access
            end
          else
            super
          end
        end

        def update_with_single_argument(other_hash, block)
          if other_hash.is_a?(HashWithIndifferentCaseInsensitiveAccess)
            regular_update(other_hash, &block)
          else
            other_hash.to_hash.each_pair do |key, value|
              if block && key?(key)
                value = block.call(self.convert_key(key), self[key], value)
              end
              self.[]=(key, value)
            end
          end
        end

    end
  end
end
