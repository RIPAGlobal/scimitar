module Scimitar
  module Resources

    # The mixin included by any class in your application which is to be mapped
    # to and exposed via a SCIM interface. Any one such class must have one
    # corresponding ResourcesController subclass declaring its association to
    # that model.
    #
    # Your class becomes responsible for implementing various *class methods*
    # as described below. YOU MUST DECLARE THESE **BEFORE** YOU INCLUDE THE
    # MIXIN MODULE because Ruby parses classes top-down and the mixin checks to
    # make sure that required methods exist, so these must be defined *first*.
    #
    #
    #
    # == scim_resource_type
    #
    # Define this method to return the Scimitar resource class that corresponds
    # to the mixing-in class.
    #
    # For example, if you have an ActiveRecord "User" class that maps to a SCIM
    # "User" resource type:
    #
    #     def self.scim_resource_type
    #       return Scimitar::Resources::User
    #     end
    #
    # This is used to render SCIM JSON data via #to_scim.
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
    # == scim_mutable_attributes
    #
    # Define this method to return a Set (preferred) or Array of names of
    # attributes which may be written in the mixing-in class.
    #
    # If you return +nil+, it is assumed that +all+ attributes mapped by
    # ::scim_attributes_map that have write accessors are eligible for
    # assignment during SCIM creation or update operations.
    #
    # For example, if everything in ::scim_attributes_map with a write accessor
    # is to be mutable over SCIM:
    #
    #     def self.scim_mutable_attributes
    #       return nil
    #     end
    #
    # Note that as a common special case, any mapped attribute of the Symbol
    # value ":id" will be removed from the list, as it is assumed to be e.g. a
    # primary key or similar. So, even though it'll have a write accessor, it
    # is not something that should be mutable over SCIM - it's taken to be your
    # internal record ID. If you do want :id included as mutable or if you have
    # a different primary key attribute name, you'll just need to return the
    # mutable attribute list directly in your ::scim_mutable_attributes method
    # rather than relying on the list extracted from ::scim_attributes_map.
    #
    #
    #
    # == scim_queryable_attributes
    #
    # Define this method to return a Hash that maps field names you wish to
    # support in SCIM filter queries to corresponding attributes in the in the
    # mixing-in class. If +nil+ then filtering is not supported in the
    # ResouceController subclass which declares that it maps to the mixing-in
    # class. If not +nil+ but a SCIM filter enquiry is made for an unmapped
    # attribute, that part of the filter will be ignored.
    #
    # For example, the SCIM 'emails' attribute has an array value with its own
    # set of properties for each entry therein, but is just searched in SCIM
    # via key "emails".
    #
    #     def self.scim_queryable_attributes
    #       return {
    #         emails: :email_address
    #       }
    #     end
    #
    module Mixin
      extend ActiveSupport::Concern

      included do
        %w{
          scim_resource_type
          scim_attributes_map
          scim_mutable_attributes
          scim_queryable_attributes
        }.each do | required_class_method_name |
          raise "You must define ::#{required_class_method_name} in #{self}" unless self.respond_to?(required_class_method_name)
        end

        # Render self as a SCIM object using ::scim_attributes_map.
        #
        def to_scim(location:)
          schema     = self.class.scim_attributes_map()
          attrs_hash = to_scim_backend(schema)
          resource   = self.class.scim_resource_type().new(attrs_hash)

          return resource.to_json()
        end

        # An instance-level method which calls ::scim_mutable_attributes and
        # either uses its returned array of mutable attribute names or reads
        # ::scim_attributes_map and determines the list from that. Caches
        # the result in an instance variable.
        #
        def scim_mutable_attributes
          @scim_mutable_attributes ||= self.class.scim_mutable_attributes()

          if @scim_mutable_attributes.nil?
            @scim_mutable_attributes = Set.new

            # Variant of https://stackoverflow.com/a/49315255
            #
            extractor = ->(enum) do
              enum.each do |key, value|
                enum = [key, value].detect(&Enumerable.method(:===))
                if enum.nil?
                  @scim_mutable_attributes << value if value.is_a?(Symbol) && self.respond_to?("#{value}=")
                else
                  extractor.call(enum)
                end
              end
            end

            extractor.call(self.class.scim_attributes_map())
            @scim_mutable_attributes.delete(:id)
          end

          @scim_mutable_attributes
        end

        # An instance level method which calls ::scim_queryable_attributes and
        # caches the result in an instance variable, for symmetry with
        # #scim_mutable_attributes and to permit potential future enhancements
        # for how the return value of ::scim_queryable_attributes is handled.
        #
        def scim_queryable_attributes
          @scim_queryable_attributes = self.class.scim_queryable_attributes()
        end

        private

          # A recursive method that takes a Hash mapping SCIM attributes to the
          # mixing in class's attributes and via ::scim_attributes_map replaces
          # symbols in the schema with the corresponding value from the user.
          #
          # Given a schema with symbols, this method will search through the
          # object for the symbols, send those symbols to the model and replace
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
