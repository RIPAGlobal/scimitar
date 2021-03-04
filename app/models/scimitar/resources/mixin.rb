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
    # are read or write and acts accordingly. At each level of the Ruby Hash,
    # the keys are case-sensitive attributes from the SCIM schema and values
    # are either Symbols, giving a corresponding read/write accessor name in
    # the mixing-in class, Hashes for nested SCIM schema data as shown below or
    # for Array entries, special structures described later.
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
    #         active: :is_active?
    #       }
    #     end
    #
    # Note that providing storage and filter (search) support for externalId is
    # VERY STRONGLY recommended (bordering on mandatory) for your service to
    # provide adequate support for typical clients to function smoothly. See
    # "scim_queryable_attributes" below for filtering.
    #
    # This omits things like "email" because in SCIM those are specified in an
    # Array, where each entry has a "type" field - e.g. "home", "work". Within
    # SCIM this is common but there are also just free lists of data, such as
    # the list of Members in a Group. This makes the mapping description more
    # complex. You can provide two kinds of mapping data:
    #
    # * One where a specific SCIM attribute is present in each array entry and
    #   can contain only a set of specific, discrete values; your mapping
    #   defines entries for each value of interest. E-mail is an example here,
    #   where "type" is the SCIM attribute and you might map "work" and "home".
    #
    # For discrete matches, you declare the Array containing Hashes with key
    # "match", where the value gives the name of the SCIM attribute to read or
    # write for each array entry; "with", where the value gives the thing to
    # match at this attribute; then "using", where the value is a Hash giving
    # a mapping schema just as described herein (schema can nest as deeply as
    # you like).
    #
    # Given that e-mails in SCIM look something like this:
    #
    #     "emails": [
    #       {
    #         "value": "bjensen@example.com",
    #         "type": "work",
    #         "primary": true
    #       },
    #       {
    #         "value": "babs@jensen.org",
    #         "type": "home"
    #       }
    #     ]
    #
    # ...then we could extend the above attributes map example thus:
    #
    #     def self.scim_attributes_map
    #       # ...
    #       emails: [
    #         {
    #           match: 'type',
    #           with:  'work',
    #           using: {
    #             value:   :work_email_address,
    #             primary: true
    #           }
    #         },
    #         {
    #           match: 'type',
    #           with:  'home',
    #           using: { value: :home_email_address }
    #         }
    #       ],
    #       # ...
    #     end
    #
    # ...where the including class would have a #work_email_address accessor
    # and we're hard-coding this as the primary (preferred) address (but could
    # just as well map this to another accessor, e.g. :work_email_is_primary?).
    #
    # * One where a SCIM array contains just a list of arbitrary entries, each
    #   with a known schema, and these map attribute-by-attribute to same-index
    #   items in a corresponding array in the mixing-in model. Group members
    #   are the example use case here.
    #
    # For things like a group's list of members, again include an array in the
    # attribute map as above but this time have a key "list" with a value that
    # is the attribute accessor in your mixing in model that returns an
    # Enumerable of values to map, then as above, "using" which provides the
    # nested schema saying how each of those objects should be mapped.
    #
    # Suppose you were mixing this module into a Team class and there was an
    # association Team#users that provided an Enumerable of team member User
    # objects:
    #
    #     def self.scim_attributes_map
    #       # ...
    #       groups: [
    #         {
    #           list: :users,          # <-- i.e. Team.users
    #           using: {
    #             value:   :id,        # <-- i.e. Team.users[n].id
    #             display: :full_name  # <-- i.e. Team.users[n].full_name
    #           }
    #         }
    #       ],
    #       #...
    #     end
    #
    # The mixing-in class _must+ implement the read accessor identified by the
    # value of the "list" key, returning any indexed, Enumerable collection
    # (e.g. an Array or ActiveRecord::Relation instance).
    #
    #
    #
    # == scim_mutable_attributes
    #
    # Define this method to return a Set (preferred) or Array of names of
    # attributes which may be written in the mixing-in class.
    #
    # If you return +nil+, it is assumed that +any+ attribute mapped by
    # ::scim_attributes_map which has a write accessor will be eligible for
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
    #         externalId: :scim_external_id,
    #         emails:     :work_email_address
    #       }
    #     end
    #
    # Filtering is currently limited and searching within e.g. arrays of data
    # is not supported; only simple top-level keys can be mapped.
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
          map             = self.class.scim_attributes_map()
          attrs_hash      = to_scim_backend(data_source: self, attrs_map_or_leaf_value: map)
          resource        = self.class.scim_resource_type().new(attrs_hash)
          meta_attrs_hash = {location: location}

          meta_attrs_hash[:created     ] = self.created_at.iso8601 if self.respond_to?(:created_at)
          meta_attrs_hash[:lastModified] = self.updated_at.iso8601 if self.respond_to?(:updated_at)

          resource.meta = Meta.new(meta_attrs_hash)
          return resource
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
          @scim_queryable_attributes ||= self.class.scim_queryable_attributes()
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
          # +data_source+::             The source of data. At the top level,
          #                             this is "self" (an instance of the
          #                             class mixing in this module).
          #
          # +attrs_map_or_leaf_value+:: The attribute map. At the top level,
          #                             this is from ::scim_attributes_map.
          #
          def to_scim_backend(data_source:, attrs_map_or_leaf_value:)
            case attrs_map_or_leaf_value
              when Hash # Expected at top-level of any map, or nested within
                attrs_map_or_leaf_value.each.with_object({}) do |(key, value), hash|
                  hash[key] = to_scim_backend(data_source: data_source, attrs_map_or_leaf_value: value)
                end

              when Array # Static or dynamic mapping against lists in data source
                built_dynamic_list = false
                mapped_array = attrs_map_or_leaf_value.map do |value|
                  if ! value.is_a?(Hash) # Unknown type, just treat as flat value
                    to_scim_backend(data_source: data_source, attrs_map_or_leaf_value: value)

                  elsif value.key?(:match) # Static map
                    static_hash = { value[:match] => value[:with] }
                    static_hash.merge!(to_scim_backend(data_source: data_source, attrs_map_or_leaf_value: value[:using]))
                    static_hash

                  elsif value.key?(:list) # Dynamic mapping of each complex list item
                    built_dynamic_list = true
                    list = data_source.public_send(value[:list])
                    list.map do |list_entry|
                      to_scim_backend(data_source: list_entry, attrs_map_or_leaf_value: value[:using])
                    end

                  else # Unknown type, just treat as flat values
                    to_scim_backend(value)

                  end
                end

                # If a dynamic list was generated, it's sitting as a nested
                # Array in the first index of the mapped result; pull it out.
                #
                mapped_array = mapped_array.first if built_dynamic_list
                mapped_array

              when Symbol # Leaf node, Symbol -> reader method to call on data source
                if data_source.respond_to?(attrs_map_or_leaf_value) # A read-accessor exists?
                  value = data_source.public_send(attrs_map_or_leaf_value)
                  value = value.to_s if value.is_a?(Numeric)
                  value
                else
                  nil
                end

              else # Leaf node, other type -> literal static value to use
                attrs_map_or_leaf_value
            end
          end

      end
    end
  end
end
