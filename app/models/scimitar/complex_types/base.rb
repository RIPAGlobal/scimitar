require 'set'

module Scimitar
  module ComplexTypes

    # This class represents complex types that could be used inside SCIM
    # resources. Each complex type must inherit from this class. They also need
    # to have their own schema defined. For example:
    #
    #     module Scimitar
    #       module ComplexTypes
    #         class Email < Base
    #           set_schema Scimitar::Schema::Email
    #
    #           def as_json(options = {})
    #             {'type' => 'work', 'primary' => true}.merge(super(options))
    #           end
    #         end
    #       end
    #     end
    #
    class Base
      include ActiveModel::Model
      include Scimitar::Schema::DerivedAttributes
      include Scimitar::Errors

      # Instantiates with attribute values - see ActiveModel::Model#initialize.
      #
      # Allows case-insensitive attributes given in options, by enumerating all
      # instance methods that exist in the subclass (at the point where this
      # method runs, 'self' is a subclass, unless someone instantiated this
      # base class directly) and subtracting methods in the base class. Usually
      # this leaves just the attribute accessors, with not much extra.
      #
      # Map a normalized case version of those names to the actual method names
      # then for each key in the inbound options, normalize it and see if one
      # of the actual case method names is available. If so, use that instead.
      #
      # Unmapped option keys will most likely have no corresponding writer
      # method in the subclass and NoMethodError will therefore arise.
      #
      def initialize(options={})
        normalized_method_map     = HashWithIndifferentAccess.new
        corrected_options         = {}
        probable_accessor_methods = self.class.instance_methods - self.class.superclass.instance_methods

        unless options.empty?
          probable_accessor_methods.each do | method_name |
            next if method_name.end_with?('=')
            normalized_method_map[method_name.downcase] = method_name
          end

          options.each do | ambiguous_case_name, value |
            normalized_name = ambiguous_case_name.downcase
            corrected_name  = normalized_method_map[normalized_name]

            if corrected_name.nil?
              corrected_options[ambiguous_case_name] = value # Probably will lead to NoMethodError
            else
              corrected_options[corrected_name] = value
            end
          end

          options = corrected_options
        end

        super # Calls into ActiveModel::Model

        @errors = ActiveModel::Errors.new(self)
      end

      # Converts the object to its SCIM representation, which is always JSON.
      #
      # +options+:: A hash that could provide default values for some of the
      #             attributes of this complex type object.
      #
      def as_json(options={})
        exclusions = options[:except] || ['errors']
        super(options.merge(except: exclusions))
      end
    end
  end
end
