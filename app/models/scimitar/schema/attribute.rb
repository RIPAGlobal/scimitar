module Scimitar
  module Schema

    # Represents an attribute of a SCIM resource that is declared in its
    # schema.
    #
    # Attributes can be simple or complex. A complex attribute needs to have
    # its own schema that is passed to the initialize method when the attribute
    # is instantiated.
    #
    # Examples:
    #
    #     Attribute.new(name: 'userName', type: 'string', uniqueness: 'server')
    #     Attribute.new(name: 'name', complexType: Scimitar::ComplexTypes::Name)
    #
    class Attribute
      include ActiveModel::Model
      include Scimitar::Errors

      attr_accessor :name,
                    :type,
                    :multiValued,
                    :required,
                    :caseExact,
                    :mutability,
                    :returned,
                    :uniqueness,
                    :subAttributes,
                    :complexType,
                    :canonicalValues

      # +options+:: Hash of values to be used for instantiating the attribute
      #             object. Some of the instance variables of the objects will
      #             have default values if this hash does not contain anything
      #             for them.
      #
      def initialize(options = {})
        defaults = {
          multiValued:     false,
          required:        false,
          caseExact:       false,
          mutability:      'readWrite',
          uniqueness:      'none',
          returned:        'default',
          canonicalValues: []
        }

        if options[:complexType]
          defaults.merge!(type: 'complex', subAttributes: options[:complexType].schema.scim_attributes)
        end

        super(defaults.merge(options || {}))
      end

      # Validates a value against this attribute object. For simple attributes,
      # it checks if blank is valid or not and if the type matches. For complex
      # attributes, it delegates it to the valid? method of the complex type
      # schema.
      #
      # If the value is not valid, validation message(s) are added to the
      # #errors attribute of this object.
      #
      # +value+:: Value to check.
      #
      # Returns +true+ if value is valid for this attribute, else +false+.
      #
      def valid?(value)
        return valid_blank? if value.blank? && !value.is_a?(FalseClass)

        if type == 'complex'
          return all_valid?(complexType, value) if multiValued
          valid_complex_type?(value)
        else
          valid_simple_type?(value)
        end
      end

      def valid_blank?
        return true unless self.required
        errors.add(self.name, 'is required')
        false
      end

      def valid_complex_type?(value)
        if !value.class.respond_to?(:schema) || value.class.schema != complexType.schema
          errors.add(self.name, 'has to follow the complexType format.')
          return false
        end
        value.class.schema.valid?(value)
        return true if value.errors.empty?
        add_errors_from_hash(errors_hash: value.errors.to_hash, prefix: self.name)
        false
      end

      def valid_simple_type?(value)
        if multiValued
          valid = value.is_a?(Array) && value.all? { |v| simple_type?(v) }
          errors.add(self.name, "or one of its elements has the wrong type. It has to be an array of #{self.type}s.") unless valid
        else
          valid = simple_type?(value)
          errors.add(self.name, "has the wrong type. It has to be a(n) #{self.type}.") unless valid
        end
        valid
      end

      def simple_type?(value)
        (type == 'string' && value.is_a?(String)) ||
          (type == 'boolean' && (value.is_a?(TrueClass) || value.is_a?(FalseClass))) ||
          (type == 'integer' && (value.is_a?(Integer))) ||
          (type == 'dateTime' && valid_date_time?(value))
      end

      def valid_date_time?(value)
        !!Time.iso8601(value)
      rescue ArgumentError
        false
      end

      def all_valid?(complex_type, value)
        validations = value.map {|value_in_array| valid_complex_type?(value_in_array)}
        validations.all?
      end

      def as_json(options = {})
        options[:except] ||= ['complexType']
        options[:except] << 'canonicalValues' if canonicalValues.empty?
        super.except(options)
      end

    end
  end
end
