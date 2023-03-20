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
    #         userName:   :username,
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
    #           list: :users,          # <-- i.e. Team.users,
    #           using: {
    #             value:   :id,        # <-- i.e. Team.users[n].id
    #             display: :full_name  # <-- i.e. Team.users[n].full_name
    #           },
    #           find_with: -> (scim_list_entry) {...} # See below
    #         }
    #       ],
    #       #...
    #     end
    #
    # The mixing-in class _must+ implement the read accessor identified by the
    # value of the "list" key, returning any indexed, Enumerable collection
    # (e.g. an Array or ActiveRecord::Relation instance). The optional key
    # ":find_with" is defined with a Proc that's passed the SCIM entry at each
    # list position. It must use this to look up the equivalent entry for
    # association via the write accessor described by the ":list" key. In the
    # example above, "find_with"'s Proc might look at a SCIM entry value which
    # is expected to be a user ID and find that User. The mapped set of User
    # data thus found would be written back with "#users=", due to the ":list"
    # key declaring the method name ":users".
    #
    # Note that you can only use either:
    #
    # * One or more static maps where each matches some other piece of source
    #   SCIM data field value, so that specific SCIM array entries are matched
    #
    # * A single dynamic list entry which maps app SCIM array entries.
    #
    # A mixture of static and dynamic data, or multiple dynamic entries in a
    # single mapping array value will produce undefined behaviour.
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
    # attribute, an 'invalid filter' exception is raised.
    #
    # If using ActiveRecord support in Scimitar::Lists::QueryParser, the mapped
    # entites are columns and that's expressed in the names of keys described
    # below; if you have other approaches to searching, these might be virtual
    # attributes or other such constructs rather than columns. That would be up
    # to your non-ActiveRecord's implementation to decide.
    #
    # Each STRING field name(s) represents a *flat* attribute path that might
    # be encountered in a filter - e.g. "name.familyName", "emails.value" (and
    # often it makes sense to define "emails" and "emails.value" identically to
    # allow for different client searching "styles", given ambiguities in RFC
    # 7644 filter examples).
    #
    # Each value is a Hash with Symbol keys ':column', naming just one simple
    # column for a mapping; ':columns', with an Array of column names that you
    # want to map using 'OR' for a single search on the corresponding SCIM
    # attribute; or ':ignore' with value 'true', which means that a fitler on
    # the matching attribute is ignored rather than resulting in an "invalid
    # filter" exception - beware possibilities for surprised clients getting a
    # broader result set than expected. Example:
    #
    #     def self.scim_queryable_attributes
    #       return {
    #         'name.givenName'  => { column: :first_name },
    #         'name.familyName' => { column: :last_name  },
    #         'emails'          => { columns: [ :work_email_address, :home_email_address ] },
    #         'emails.value'    => { columns: [ :work_email_address, :home_email_address ] },
    #         'emails.type'     => { ignore: true }
    #       }
    #     end
    #
    # Filtering is currently limited and searching within e.g. arrays of data
    # is not supported; only simple top-level keys can be mapped.
    #
    #
    # == Optional methods
    #
    # === scim_timestamps_map
    #
    # If you implement this class method, it should return a Hash with one or
    # both of the keys 'created' and 'lastModified', as Symbols. The values
    # should be methods that the including method supports which return a
    # creation or most-recently-updated time, respectively. The returned object
    # mustsupport #iso8601 to convert to a String representation. Example for a
    # typical ActiveRecord object with standard timestamps:
    #
    #     def self.scim_timestamps_map
    #       {
    #         created:      :created_at,
    #         lastModified: :updated_at
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
            extractor = ->(outer_enum) do
              outer_enum.each do |key, value|
                enum = [key, value].detect(&Enumerable.method(:===))
                if enum.nil?
                  @scim_mutable_attributes << value if value.is_a?(Symbol) && self.respond_to?("#{value}=")
                else
                  if enum.is_a?(Hash)
                    extractor.call(enum)
                  elsif enum.is_a?(Array)
                    enum.each do | static_or_dynamic_mapping |
                      if static_or_dynamic_mapping.key?(:match) # Static
                        extractor.call(static_or_dynamic_mapping[:using])
                      elsif static_or_dynamic_mapping.key?(:find_with) # Dynamic
                        @scim_mutable_attributes << static_or_dynamic_mapping[:list]
                      end
                    end
                  end
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

        # Render self as a SCIM object using ::scim_attributes_map.
        #
        # +location+:: The location (HTTP(S) full URI) of this resource, in the
        #              domain of the object including this mixin - "your" IDs,
        #              not the remote SCIM client's external IDs. #url_for is a
        #              good way to generate this.
        #
        def to_scim(location:)
          map             = self.class.scim_attributes_map()
          timestamps_map  = self.class.scim_timestamps_map() if self.class.respond_to?(:scim_timestamps_map)
          attrs_hash      = self.to_scim_backend(data_source: self, attrs_map_or_leaf_value: map)
          resource        = self.class.scim_resource_type().new(attrs_hash)
          meta_attrs_hash = { location: location }

          meta_attrs_hash[:created     ] = self.send(timestamps_map[:created     ])&.iso8601(0) if timestamps_map&.key?(:created)
          meta_attrs_hash[:lastModified] = self.send(timestamps_map[:lastModified])&.iso8601(0) if timestamps_map&.key?(:lastModified)

          resource.meta = Meta.new(meta_attrs_hash)
          return resource
        end

        # Update self from a SCIM object using ::scim_attributes_map. This does
        # NOT PERSIST ("save") 'this' instance - it just sets attribute values
        # within it.
        #
        # If you are mixing into an ActiveRecord subclass then depending on how
        # your ::scim_attributes_map updates associated objects (if any), Rails
        # might make database writes to update those associations immediately.
        # Given this, it is highly recommended that you wrap calls to this
        # method and your subsequent save of 'self' inside a transaction.
        #
        #     ActiveRecord::Base.transaction do
        #       record.from_scim!(scim_hash: some_payload)
        #       record.save!
        #     end
        #
        # Call ONLY for POST or PUT. For PATCH, see #from_scim_patch!.
        #
        # +scim_hash+:: A Hash that's the result of parsing a JSON payload
        #               from an inbound POST or PUT request.
        #
        # Returns 'self', for convenience of e.g. chaining other methods.
        #
        def from_scim!(scim_hash:)
          scim_hash.freeze()
          map = self.class.scim_attributes_map().freeze()

          self.from_scim_backend!(attrs_map_or_leaf_value: map, scim_hash_or_leaf_value: scim_hash)
          return self
        end

        # Update self from a SCIM object representing a PATCH operation. This
        # does NOT PERSIST ("save") 'this' instance - it just sets attribute
        # values within it.
        #
        # SCIM patch operations are complex. A series of operations is given,
        # each asking to add, remove or replace specific attributes or, via
        # filters, potentially multiple attributes if the filter matches many.
        #
        # Pass the PATCH payload. Then:
        #
        # * This instance (self) is converted to a SCIM representation via
        #   calling #to_scim.
        #
        # * The inbound operations are applied. A Scimitar::ErrorResponse may
        #   be thrown if the patch data looks bad - if you are calling from a
        #   Scimitar::ActiveRecordBackedResourcesController subclass, this will
        #   be handled for you and returned as an appropriate HTTP response.
        #   Otherwise, you'll need to rescue it yourself and e.g. make use of
        #   Scimitar::ApplicationController#handle_scim_error, passing the
        #   exception object to it, if you are a subclass of that base class.
        #
        # * The (possibly) updated SCIM representation of 'self' is pushed
        #   back into 'this' instance via #from_scim!.
        #
        # IMPORTANT: Please see #from_scim! for notes about associations and
        # use of transactions with ActiveRecord.
        #
        # Call ONLY for PATCH. For POST and PUT, see #from_scim!.
        #
        def from_scim_patch!(patch_hash:)
          frozen_ci_patch_hash = patch_hash.with_indifferent_case_insensitive_access().freeze()
          ci_scim_hash         = self.to_scim(location: '(unused)').as_json().with_indifferent_case_insensitive_access()

          frozen_ci_patch_hash['operations'].each do |operation|
            nature   = operation['op'   ]&.downcase
            path_str = operation['path' ]
            value    = operation['value']

            unless ['add', 'remove', 'replace'].include?(nature)
              raise Scimitar::InvalidSyntaxError.new("Unrecognised PATCH \"op\" value of \"#{nature}\"")
            end

            # https://tools.ietf.org/html/rfc7644#section-3.5.2.2
            #
            # o  If "path" is unspecified, the operation fails with HTTP status
            #    code 400 and a "scimType" error code of "noTarget".
            #
            # (...for "add" or "replace", no path means "whole object").
            #
            if nature == 'remove' && path_str.blank?
              raise Scimitar::ErrorResponse.new(
                status:    400,
                scimType: 'noTarget',
                detail:   'No "path" target given for "replace" operation'
              )
            end

            # Deal with the exception case of no path, where the entire object
            # is addressed. It's easier internally to treat a path as a set of
            # steps towards a final Hash key (attribute) with an associated
            # value to change (and filters may apply if the value is an Array).
            #
            extract_root = false
            if path_str.blank?
              extract_root = true
              path_str     = 'root'
              ci_scim_hash = { 'root' => ci_scim_hash }.with_indifferent_case_insensitive_access()
            end

            # Handle extension schema. Contributed by @bettysteger and
            # @MorrisFreeman via:
            #
            #   https://github.com/RIPAGlobal/scimitar/issues/48
            #   https://github.com/RIPAGlobal/scimitar/pull/49
            #
            # Note the ":" separating the schema ID (URN) from the attribute.
            # The nature of JSON rendering / other payloads might lead you to
            # expect a "." as with any complex types, but that's not the case;
            # see https://tools.ietf.org/html/rfc7644#section-3.10, or
            # https://tools.ietf.org/html/rfc7644#section-3.5.2 of which in
            # particular, https://tools.ietf.org/html/rfc7644#page-35.
            #
            paths = []
            self.class.scim_resource_type.extended_schemas.each do |schema|
              path_str.downcase.split(schema.id.downcase + ':').drop(1).each do |path|
                paths += [schema.id] + path.split('.')
              end
            end
            paths = path_str.split('.') if paths.empty?

            self.from_patch_backend!(
              nature:        nature,
              path:          paths,
              value:         value,
              altering_hash: ci_scim_hash
            )

            if extract_root
              ci_scim_hash = ci_scim_hash['root']
            end
          end

          self.from_scim!(scim_hash: ci_scim_hash)
          return self
        end

        private # (...but note that we're inside "included do" within a mixin)

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
                  if ! value.is_a?(Hash)
                    raise 'Bad attribute map: Array contains someting other than mapping Hash(es)'

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
                    raise 'Bad attribute map: Mapping Hash inside Array does not contain supported data'

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

          # Given a SCIM resource representation (left) and an attribute map to
          # an instance of the mixin-including class / 'self' (right), walk the
          # attribute map, looking up equivalent values in the SCIM resource.
          # Mutable attributes will be set from the SCIM data, or cleared if
          # the SCIM data has nothing set ("PUT" semantics; splat resource data
          # in full, writing all mapped attributes).
          #
          # * Literal map values like 'true' are for read-time uses; ignored.
          # * Symbol map values are treated as read accessor method names and a
          #   write accessor checked for by adding "=". If this method exists,
          #   a value write is attempted using the SCIM resource data.
          # * Static and dynamic array mappings perform as documented for
          #   ::scim_attributes_map.
          #
          #     {                                                     | {
          #       "userName": "foo",                                  |   'id': :id,
          #       "name": {                                           |   'externalId': :scim_uid,
          #         "givenName": "Foo",                               |   'userName': :username,
          #         "familyName": "Bar"                               |   'name': {
          #       },                                                  |     'givenName': :first_name,
          #       "active": true,                                     |     'familyName': :last_name
          #       "emails": [                                         |   },
          #         {                                                 |   'emails': [
          #           "type": "work",                  <------\       |     {
          #           "primary": true,                         \------+---    'match': 'type',
          #           "value": "foo.bar@test.com"                     |       'with': 'work',
          #         }                                                 |       'using': {
          #       ],                                                  |         'value': :work_email_address,
          #       "phoneNumbers": [                                   |         'primary': true
          #         {                                                 |       }
          #           "type": "work",                                 |     }
          #           "primary": false,                               |   ],
          #           "value": "+642201234567"                        |   groups: [
          #         }                                                 |     {
          #       ],                                                  |       list:  :groups,
          #       "id": "42",                                         |       using: {
          #       "externalId": "AA02984",                            |         value:   :id,
          #       "meta": {                                           |         display: :full_name
          #         "location": "https://test.com/mock_users/42",     |       }
          #         "resourceType": "User"                            |     }
          #       },                                                  |   ],
          #       "schemas": [                                        |   'active': :is_active
          #         "urn:ietf:params:scim:schemas:core:2.0:User"      | }
          #       ]                                                   |
          #     }                                                     |
          #
          # Named parameters:
          #
          # +attrs_map_or_leaf_value+:: Attribute map; recursive calls just
          #                             pass in the fragment for recursion, so
          #                             at the deepest level, this ends up
          #                             being a leaf node which may have a
          #                             Symbol method name, used to look for a
          #                             write accessor; or a read-only literal,
          #                             which is ignored (right hand side of
          #                             the ASCII art diagram).
          #
          # +scim_hash_or_leaf_value+:: Similar to +attrs_map_or_leaf_value+
          #                             but tracks the SCIM schema data being
          #                             read as input source material (left
          #                             hand side of the ASCII art diagram).
          #
          # +path+::                    Array of SCIM attribute names giving a
          #                             path into the SCIM schema where
          #                             iteration has reached. Used to find the
          #                             schema attribute definiton and check
          #                             mutability before writing.
          #
          def from_scim_backend!(
            attrs_map_or_leaf_value:,
            scim_hash_or_leaf_value:,
            path: []
          )
            scim_hash_or_leaf_value = scim_hash_or_leaf_value.with_indifferent_case_insensitive_access() if scim_hash_or_leaf_value.is_a?(Hash)

            # We get the schema via this instance's class's resource type, even
            # if we end up in collections of other types - because it's *this*
            # schema at the top level that defines the attributes of interest
            # within any collections, not SCIM schema - if any - for the items
            # within the collection (a User's "groups" per-array-entry schema
            # is quite different from the Group schema).
            #
            resource_class = self.class.scim_resource_type()

            case attrs_map_or_leaf_value
              when Hash # Nested attribute-value pairs
                attrs_map_or_leaf_value.each do | scim_attribute, sub_attrs_map_or_leaf_value |
                  next if scim_attribute&.to_s&.downcase == 'id' && path.empty?

                  # Handle extension schema. Contributed by @bettysteger and
                  # @MorrisFreeman via:
                  #
                  #   https://github.com/RIPAGlobal/scimitar/issues/48
                  #   https://github.com/RIPAGlobal/scimitar/pull/49
                  #
                  attribute_tree = []
                  resource_class.extended_schemas.each do |schema|
                    attribute_tree << schema.id and break if schema.scim_attributes.any? { |attribute| attribute.name == scim_attribute.to_s }
                  end
                  attribute_tree << scim_attribute.to_s

                  sub_scim_hash_or_leaf_value = scim_hash_or_leaf_value&.dig(*attribute_tree)

                  self.from_scim_backend!(
                    attrs_map_or_leaf_value: sub_attrs_map_or_leaf_value,
                    scim_hash_or_leaf_value: sub_scim_hash_or_leaf_value, # May be 'nil'
                    path:                    path + [scim_attribute]
                  )
                end

              when Array # Static or dynamic maps
                attrs_map_or_leaf_value.each_with_index do | mapped_array_entry |
                  next unless mapped_array_entry.is_a?(Hash)

                  if mapped_array_entry.key?(:match) # Static map
                    attr_to_match  = mapped_array_entry[:match].to_s
                    value_to_match = mapped_array_entry[:with]
                    sub_attrs_map  = mapped_array_entry[:using]

                    # Search for the array entry in the SCIM object that
                    # matches the thing we're looking for via :match & :with.
                    #
                    found_source_list_entry = scim_hash_or_leaf_value&.find do | scim_array_entry |
                      scim_array_entry[attr_to_match] == value_to_match
                    end

                    self.from_scim_backend!(
                      attrs_map_or_leaf_value: sub_attrs_map,
                      scim_hash_or_leaf_value: found_source_list_entry, # May be 'nil'
                      path:                    path
                    )

                  elsif mapped_array_entry.key?(:list) # Dynamic mapping of each complex list item
                    attribute = resource_class.find_attribute(*path)
                    method    = "#{mapped_array_entry[:list]}="

                    if (attribute&.mutability == 'readWrite' || attribute&.mutability == 'writeOnly') && self.respond_to?(method)
                      find_with_proc = mapped_array_entry[:find_with]

                      unless find_with_proc.nil?
                        mapped_list = (scim_hash_or_leaf_value || []).map do | source_list_entry |
                          find_with_proc.call(source_list_entry)
                        end

                        mapped_list.compact!

                        self.public_send(method, mapped_list)
                      end
                    end
                  end # "elsif mapped_array_entry.key?(:list)"
                end # "map_entry&.each do | mapped_array_entry |"

              when Symbol # Setter/getter method at leaf position in attribute map
                if path.length == 1 && path.first&.to_s&.downcase == 'externalid' # Special case held only in schema base class
                  mutable = true
                else
                  attribute = resource_class.find_attribute(*path)
                  mutable   = attribute&.mutability == 'readWrite' || attribute&.mutability == 'writeOnly'
                end

                if mutable
                  method = "#{attrs_map_or_leaf_value}="
                  self.public_send(method, scim_hash_or_leaf_value) if self.respond_to?(method)
                end

              # else - fixed value of interest in #to_scim only.

            end # "case scim_hash_or_leaf_value"
          end # "def from_scim_backend!..."

          # Recursive back-end for #from_scim_patch! which traverses paths down
          # into one or - if multiple-match filters are encountered - multiple
          # attributes and performs updates on a SCIM Hash representation of
          # 'self'. Throws Scimitar::ErrorResponse (or a subclass thereof) upon
          # encountering any errors.
          #
          # Named parameters:
          #
          # +nature+::        The PATCH operation nature - MUST be a lower case
          #                   String of 'add', 'remove' or 'replace' ONLY.
          #
          # +path+::          Operation path, as a series of array entries (so
          #                   an inbound dot-separated path string would first
          #                   be split into an array by the caller). For
          #                   internal recursive calls, this will
          #
          # +value+::         The value to apply at the attribute(s) identified
          #                   by +path+. Ignored for 'remove' operations.
          #
          # +altering_hash+:: The Hash to operate on at the current +path+. For
          #                   recursive calls, this will be some way down into
          #                   the SCIM representation of 'self'. MUST be a
          #                   HashWithIndifferentCaseInsensitiveAccess.
          #
          # Note that SCIM PATCH operations permit *no* path for 'replace' and
          # 'add' operations, meaning "apply to whole object". To avoid special
          # case code in the back-end, callers should in such cases add their
          # own wrapping Hash with a single key addressing the SCIM object of
          # interest and supply this key as the sole array entry in +path+.
          #
          def from_patch_backend!(nature:, path:, value:, altering_hash:)
            raise 'Case sensitivity violation' unless altering_hash.is_a?(Scimitar::Support::HashWithIndifferentCaseInsensitiveAccess)

            # These all throw exceptions if data is not as expected / required,
            # any of which are rescued below.
            #
            if path.count == 1
              from_patch_backend_apply!(
                nature:        nature,
                path:          path,
                value:         value,
                altering_hash: altering_hash
              )
            else
              from_patch_backend_traverse!(
                nature:        nature,
                path:          path,
                value:         value,
                altering_hash: altering_hash
              )
            end

            # Treat all exceptions as a malformed or unsupported PATCH.
            #
            rescue => _exception # You can use _exception if debugging
              raise Scimitar::InvalidSyntaxError.new('PATCH describes unrecognised attributes and/or unsupported filters')
          end

          # Called by #from_patch_backend! when dealing with path elements that
          # is not yet the final (leaf) entry. Deals with filters etc. and
          # traverses down one path level, making one or more recursive calls
          # back up into #from_patch_backend!
          #
          # Parameters are as for #from_patch_backend!, where +path+ is assumed
          # to have at least two entries.
          #
          # Happily throws exceptions if data is not as expected / required.
          #
          def from_patch_backend_traverse!(nature:, path:, value:, altering_hash:)
            raise 'Case sensitivity violation' unless altering_hash.is_a?(Scimitar::Support::HashWithIndifferentCaseInsensitiveAccess)

            path_component, filter = extract_filter_from(path_component: path.first)

            # https://tools.ietf.org/html/rfc7644#section-3.5.2.1
            #
            # o  If the target location specifies an attribute that does not exist
            #    (has no value), the attribute is added with the new value.
            #
            # https://tools.ietf.org/html/rfc7644#section-3.5.2.3
            #
            # o  If the target location path specifies an attribute that does not
            #    exist, the service provider SHALL treat the operation as an "add".
            #
            # Harmless in this context for 'remove'.
            #
            altering_hash[path_component] ||= Scimitar::Support::HashWithIndifferentCaseInsensitiveAccess.new

            # Unless the PATCH is bad, inner data is an Array or Hash always as
            # by definition this method is only called at path positions above
            # the leaf (target attribute-to-modify) node.
            #
            inner_data = altering_hash[path_component]

            found_data_for_recursion = if filter
              matched_hashes = []

              all_matching_filter(filter: filter, within_array: inner_data) do | matched_hash, _matched_index |
                matched_hashes << matched_hash
              end

              # Same reason as section 3.5.2.1 / 3.5.2.3 RFC quotes above.
              #
              if nature != 'remove' && matched_hashes.empty?
                new_hash = Scimitar::Support::HashWithIndifferentCaseInsensitiveAccess.new
                altering_hash[path_component] = [new_hash]
                matched_hashes                = [new_hash]
              end

              matched_hashes
            else
              [ inner_data ]
            end

            found_data_for_recursion.each do | found_data |
              self.from_patch_backend!(
                nature:        nature,
                path:          path[1..-1],
                value:         value,
                altering_hash: found_data
              )
            end
          end

          # Called by #from_patch_backend! when dealing with path the last path
          # element; applies the operation nature and value. Deals with filters
          # etc. in this final path position (filters only being relevant for
          # 'remove' or 'replace' operations).
          #
          # Parameters are as for #from_patch_backend!, where +path+ is assumed
          # to have exactly one entry only.
          #
          # Happily throws exceptions if data is not as expected / required.
          #
          def from_patch_backend_apply!(nature:, path:, value:, altering_hash:)
            raise 'Case sensitivity violation' unless altering_hash.is_a?(Scimitar::Support::HashWithIndifferentCaseInsensitiveAccess)

            path_component, filter = extract_filter_from(path_component: path.first)
            current_data_at_path   = altering_hash[path_component]

            if current_data_at_path.nil?
              case nature
                when 'add', 'replace'
                  if filter.present? # Implies we expected to replace/add to an item matched inside an array
                    altering_hash[path_component] = [value]
                  else
                    altering_hash[path_component] = value
                  end
                when 'remove'
                  # Nothing to do - no data here anyway
              end

            # Path filters are not described for 'add' and assumed to have no
            # meaning - https://tools.ietf.org/html/rfc7644#section-3.5.2.1
            #
            elsif filter.present? && nature != 'add'
              compact_after = false
              found_matches = false

              all_matching_filter(filter: filter, within_array: current_data_at_path) do | matched_hash, matched_index |
                found_matches = true

                case nature
                  when 'remove'
                    current_data_at_path[matched_index] = nil
                    compact_after = true
                  when 'replace'
                    matched_hash.reject! { true }
                    matched_hash.merge!(value)
                end
              end

              current_data_at_path.compact! if compact_after

              # https://tools.ietf.org/html/rfc7644#section-3.5.2.1
              #
              # o  If the target location specifies an attribute that does not exist
              #    (has no value), the attribute is added with the new value.
              #
              # https://tools.ietf.org/html/rfc7644#section-3.5.2.3
              #
              # o  If the target location path specifies an attribute that does not
              #    exist, the service provider SHALL treat the operation as an "add".
              #
              current_data_at_path << value unless found_matches || nature == 'remove'

            else
              case nature
                when 'add'
                  if current_data_at_path.is_a?(Array)
                    altering_hash[path_component] += value
                  elsif current_data_at_path.is_a?(Hash)

                    # Need to dive down inside a Hash value for additions; a
                    # deep merge isn't enough. Take this Group example where
                    # nature is "add" and value is:
                    #
                    #     "members":[
                    #       {
                    #         "value":"<user-id>"
                    #       }
                    #     ]
                    #
                    # ...in that case, a deep merge would *replace* the array
                    # at key 'members' with the above, rather than adding.
                    #
                    value.keys.each do | key |
                      from_patch_backend!(
                        nature:        nature,
                        path:          path + [key],
                        value:         value[key],
                        altering_hash: altering_hash
                      )
                    end
                  else
                    altering_hash[path_component] = value
                  end

                when 'replace'
                  if path_component == 'root'
                    altering_hash[path_component].merge!(value)
                  else
                    altering_hash[path_component] = value
                  end

                # The array check handles payloads seen from e.g. Microsoft for
                # remove-user-from-group, where contrary to examples in the RFC
                # which would imply "payload removes all users", there is the
                # clear intent to remove just one.
                #
                # https://tools.ietf.org/html/rfc7644#section-3.5.2.2
                # https://learn.microsoft.com/en-us/azure/active-directory/app-provisioning/use-scim-to-provision-users-and-groups#update-group-remove-members
                #
                # Since remove-all in the face of remove-one is destructive, we
                # do a special check here to see if there's an array value for
                # the array path that the payload yielded. If so, we can match
                # each value against array items and remove just those items.
                #
                # There is an additional special case to handle a bad example
                # from Salesforce:
                #
                #   https://help.salesforce.com/s/articleView?id=sf.identity_scim_manage_groups.htm&type=5
                #
                when 'remove'
                  if altering_hash[path_component].is_a?(Array) && value.present?

                    # Handle bad Salesforce example. That might be simply a
                    # documentation error, but just in case...
                    #
                    value = value.values.first if (
                      path_component&.downcase == 'members' &&
                      value.is_a?(Hash)                     &&
                      value.keys.size == 1                  &&
                      value.keys.first&.downcase == 'members'
                    )

                    # The Microsoft example provides an array of values, but we
                    # may as well cope with a value specified 'flat'. Promote
                    # such a thing to an Array to simplify the following code.
                    #
                    value = [value] unless value.is_a?(Array)

                    # For each value item, delete matching array entries. The
                    # concept of "matching" is:
                    #
                    # * For simple non-Hash values (if possible) just delete on
                    #   an exact match
                    #
                    # * For Hash-based values, only delete if all 'patch' keys
                    #   are present in the resource and all values thus match.
                    #
                    # Special case to ignore '$ref' from the Microsoft payload.
                    #
                    # Note coercion to strings to account for SCIM vs the usual
                    # tricky case of underlying implementations with (say)
                    # integer primary keys, which all end up as strings anyway.
                    #
                    value.each do | value_item |
                      altering_hash[path_component].delete_if do | item |
                        if item.is_a?(Hash) && value_item.is_a?(Hash)
                          matched_all = true
                          value_item.each do | value_key, value_value |
                            next if value_key == '$ref'
                            if ! item.key?(value_key) || item[value_key]&.to_s != value_value&.to_s
                              matched_all = false
                            end
                          end
                          matched_all
                        else
                          item&.to_s == value_item&.to_s
                        end
                      end
                    end
                  else
                    altering_hash.delete(path_component)
                  end

              end
            end
          end

          # Given a path element from SCIM, splits this into the attribute and
          # filter parts. Returns a tuple of [attribute, filter] where +filter+
          # will be +nil+ if no filter string was given.
          #
          # Named parameters:
          #
          # +path_component+:: Path component to examine (a String), e.g.
          #                    'userName' or 'emails[type eq "work"]'.
          #
          # Happily throws exceptions if data is not as expected / required.
          #
          def extract_filter_from(path_component:)
            filter = nil

            if path_component.include?('[')
              composition    = path_component.split(/[\[\]]/) # "attribute_name[filter_string]" -> ["attribute_name", "filter_string"]
              path_component = composition.first
              filter         = composition.last
            end

            [path_component, filter]
          end

          # Given a SCIM filter string and array of Hashes from a SCIM object,
          # search for matches within the array and invoke a given block for
          # each.
          #
          # Obtain filter strings by calling #extract_filter_from.
          #
          # TODO: Support more complex matchers than 'attr eq "value"'.
          #
          # Named parameters:
          #
          # +filter+::       Filter string, e.g. 'type eq "work"'.
          # +within_array+:: Array to search.
          #
          # You must pass a block. It is invoked with each matching array entry
          # (a Hash) and the index into +within_array+ at which this was found.
          #
          # Happily throws exceptions if data is not as expected / required.
          #
          def all_matching_filter(filter:, within_array:, &block)
            filter_components = filter.split(' ', 3)

            attribute = filter_components[0]
            operator  = filter_components[1]
            value     = filter_components[2]

            # Quoted value includes closing quote but has data afterwards?
            # Bad; implies extra conditions, e.g. '...eq "one two" and..." or
            # just junk data.
            #
            # Value is *not* quoted but contains a space? Means there must be
            # again either extra conditions or trailing junk data.
            #
            raise "Unsupported matcher #{filter.inspect}" if (
              filter_components.size != 3         ||
              operator.downcase != 'eq'           ||
              value.strip.match?(/\".+[^\\]\".+/) || # Literal '"', any data, no-backslash-then-literal (unescaped) '"', more data
              (!value.start_with?('"') && value.strip.include?(' '))
            )

            value = value[1..-2] if value.start_with?('"') && value.end_with?('"')

            within_array.each.with_index do | hash, index |
              ci_hash = hash.with_indifferent_case_insensitive_access()
              matched = ci_hash.key?(attribute) && ci_hash[attribute]&.to_s == value&.to_s

              yield(hash, index) if matched
            end
          end

      end # "included do"
    end # "module Mixin"
  end # "module Resources"
end # "module Scimitar"
