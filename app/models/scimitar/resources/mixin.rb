module Scimitar
  module Resources

    # The mixin included by any class in your application which is to be mapped
    # to and exposed via a SCIM interface. Any one such class must have one
    # corresponding ResourcesController subclass declaring its association to
    # that model.
    #
    # Your class becomes responsible for implementing various *class methods*
    # as described below.
    #
    #
    #
    # == scim_schemas
    #
    # Define this method to return an Array of Strings giving the SCIM schemas
    # against which your class will map attributes (see ::scim_attributes_map).
    #
    # For a user-like class mapping to the SCIM standard User, this would be
    # <tt>['urn:ietf:params:scim:schemas:core:2.0:User']</tt>. If you included
    # extra attributes from the Enterprise extension, you would add in
    # <tt>''</tt> to that Array.
    #
    # For a group-of-users-like class mapping to the SCIM standard Group, this
    # would be <tt>['urn:ietf:params:scim:schemas:core:2.0:Group']</tt>.
    #
    # For a custom class, you'd need to define and list one or more custom
    # schema URNs or an Array with an empty string if the intended clients for
    # your API don't require a schema URN when dealing with your custom type.
    # That's well beyond the scope of the Scimitar gem's remit.
    #
    # Example:
    #
    #     def self.scim_schemas
    #       return ['urn:ietf:params:scim:schemas:core:2.0:User']
    #     end
    #
    #
    #
    # == scim_attributes_map
    #
    # Define this method to return a Hash that maps SCIM attributes to
    # corresponding supported accessor methods in the mixing-in class.
    #
    # Define read-only, write-only or read-write attributes here. Scimitar will
    # check for an appropriate accessor depending on whether SCIM operations
    # are read or write and acts accordingly.
    #
    # For example, for a User model <-> SCIM user:
    #
    #     def self.scim_attributes_map
    #       return {
    #         id:         :id,
    #         externalId: :scim_external_id,
    #         userName:   :user_name,
    #         name:       {
    #           givenName:  :given_name,
    #           familyName: :last_name
    #         },
    #         emails: [
    #           {
    #             value: :email
    #           },
    #         ],
    #         active: :is_active?
    #       }
    #     end
    #
    #
    #
    # == scim_mutable_attrbutes
    #
    # Define this method to return a Set (preferred) or Array of names
    # of attributes which may be written in the mixing-in class.
    #
    # If you return +nil+, it is assumed that +all+ attributes mapped by
    # ::scim_attributes_map that have write accessors are eligible for
    # assignment during SCIM creation or update operations.
    #
    # For example, if everything in ::scim_attributes_map with a write
    # accessor is to be mutable over SCIM:
    #
    #    def self.scim_mutable_attrbutes
    #      return nil
    #    end
    #
    #
    #
    # == scim_queryable_attributes
    #
    # Define this method to return a Set (preferred) or Array of names of
    # attributes which may be queried via SCIM in the mixing-in class. If
    # +nil+, filtering is not supported in the ResouceController subclass
    # which declares that it maps to the mixing-in class.
    #
    # For example:
    #
    #     def self.scim_queryable_attributes
    #       return nil
    #     end
    #
    module Mixin
      extend ActiveSupport::Concern

      included do
        %w{
          scim_schemas
          scim_attributes_map
          scim_mutable_attrbutes
          scim_queryable_attributes
        }.each do | required_class_method_name |
          raise "You must define ::#{required_class_method_name} in #{self}" unless self.respond_to?(required_class_method_name)
        end

        # Render self as a SCIM object using ::scim_attributes_map.

        def to_scim(location:)
          schema = self.class.scim_attributes_map()
          return to_scim_backend(object)
        end

        # A recursive method that takes a Hash mapping SCIM attributes to the
        # mixing in class's attributes and via ::scim_attributes_map replaces
        # symbols in the schema with the corresponding value from the user.
        #
        # Given a schema with symbols, this method will search through the
        # object for the symbols, send those symbols to the model, and replace
        # the symbol with the return value.
        #
        def to_scim_backend(object)
          case object
            when Hash
              object.each.with_object({}) do |(key, value), hash|
                hash[key] = to_scim_backend(value)
              end

            when Array
              object.map do |value|
                to_scim_backend(value)
              end

            when Symbol
              if self.respond_to?(object) # A read-accessor exists
                self.public_send(object)
              else
                nil
              end

            else
              object
          end
        end
      end
    end
  end
end
