# Scimitar

[![Gem Version](https://badge.fury.io/rb/scimitar.svg)](https://badge.fury.io/rb/scimitar)
[![Build Status](https://app.travis-ci.com/RIPAGlobal/scimitar.svg?branch=main)](https://app.travis-ci.com/RIPAGlobal/scimitar)
[![License](https://img.shields.io/badge/license-mit-blue.svg)](https://opensource.org/licenses/MIT)

A SCIM v2 API endpoint implementation for Ruby On Rails.



## Overview

System for Cross-domain Identity Management (SCIM) is a protocol that helps systems synchronise user data between different business systems. A _service provider_ hosts a SCIM API endpoint implementation and the Scimitar gem is used to help quickly build this implementation. One or more _enterprise subscribers_ use these APIs to let that service know about changes in the enterprise's user (employee) list.

In the context of the names used by the SCIM standard, the service that is provided is some kind of software-as-a-service solution that the enterprise subscriber uses to assist with their day to day business. The enterprise maintains its user (employee) list via whatever means it wants, but includes SCIM support so that any third party services it uses can be kept up to date with adds, removals or changes to employee data.

* [Overview](https://en.wikipedia.org/wiki/System_for_Cross-domain_Identity_Management) at Wikipedia
* [More detailed introduction](http://www.simplecloud.info) at SimpleCloud
* SCIM v2 RFC [7642](https://tools.ietf.org/html/rfc7642): Concepts
* SCIM v2 RFC [7643](https://tools.ietf.org/html/rfc7643): Core schema
* SCIM v2 RFC [7644](https://tools.ietf.org/html/rfc7644): Protocol



## Installation

Install using:

```shell
gem install scimitar
```

In your Gemfile:

```ruby
gem 'scimitar', '~> 1.0'
```

Scimitar uses [semantic versioning](https://semver.org) so you can be confident that patch and minor version updates for features, bug fixes and/or security patches will not break your application.



## Heritage

Scimitar borrows heavily - to the point of cut-and-paste - from:

* [ScimEngine](https://github.com/Cisco-AMP/scim_engine) for the Rails controllers and resource-agnostic subclassing approach that makes supporting User and/or Group, along with custom resource types if you need them, quite easy.
* [ScimRails](https://github.com/lessonly/scim_rails) for the bearer token support, 'index' actions and filter support.
* [SCIM Query Filter Parser](https://github.com/ingydotnet/scim-query-filter-parser-rb) for advanced filter handling.

All three are provided under the MIT license. Scimitar is too.



## Usage

Scimitar is best used with Rails and ActiveRecord, but it can be used with other persistence back-ends too - you just have to do more of the work in controllers using Scimitar's lower level controller subclasses, rather than relying on Scimitar's higher level ActiveRecord abstractions.

### Authentication

Noting the _Security_ section later - to set up an authentication method, create a `config/initializers/scimitar.rb` in your Rails application and define a token-based authenticator and/or a username-password authenticator in the [engine configuration section documented in the sample file](https://github.com/RIPAGlobal/scimitar/blob/main/config/initializers/scimitar.rb). For example:

```ruby
Scimitar.engine_configuration = Scimitar::EngineConfiguration.new({
  token_authenticator: Proc.new do | token, options |

    # This is where you'd write the code to validate `token` - the means by
    # which your application issues tokens to SCIM clients, or validates them,
    # is outside the scope of the gem; the required mechanisms vary by client.
    # More on this can be found in the 'Security' section later.
    #
    SomeLibraryModule.validate_access_token(token)

  end
})
```

When it comes to token access, Scimitar neither enforces nor presumes any kind of encoding for bearer tokens. You can use anything you like, including encoding/encrypting JWTs if you so wish - https://rubygems.org/gems/jwt may be useful. The way in which a client might integrate with your SCIM service varies by client and you will have to check documentation to see how a token gets conveyed to that client in the first place (e.g. a full OAuth flow with your application, or just a static token generated in some UI which an administrator copies and pastes into their client's SCIM configuration UI).

### Routes

For each resource you support, add these lines to your `routes.rb`:

```ruby
namespace :scim_v2 do
  mount Scimitar::Engine, at: '/'

  get    'Users',     to: 'users#index'
  get    'Users/:id', to: 'users#show'
  post   'Users',     to: 'users#create'
  put    'Users/:id', to: 'users#replace'
  patch  'Users/:id', to: 'users#update'
  delete 'Users/:id', to: 'users#destroy'
end
```

All routes then will be available at `https://.../scim_v2/...` via controllers you write in `app/controllers/scim_v2/...`, e.g. `app/controllers/scim_v2/users_controller.rb`. More on controllers later.

### Data models

Scimitar assumes that each SCIM resource maps to a single corresponding class in your system. This might be an abstraction over more complex underpinings, but either way, a 1:1 relationship is expected. For example, a SCIM User might map to a User ActiveRecord model in your Rails application, while a SCIM Group might map to some custom class called Team which operates on a more complex set of data "under the hood".

Before writing any controllers, it's a good idea to examine the SCIM specification and figure out how you intend to map SCIM attributes in any resources of interest, to your local data. A [mixin is provided](https://github.com/RIPAGlobal/scimitar/blob/main/app/models/scimitar/resources/mixin.rb) which you can include in any plain old Ruby class (including, but not limited to ActiveRecord model classes) - a more readable form of the comments in this file [is in the RDoc output](https://www.rubydoc.info/gems/scimitar/Scimitar/Resources/Mixin).

The functionality exposed by the mixin is relatively complicated because the range of operations that the SCIM API supports is quite extensive. Rather than duplicate all the information here, please see the extensive comments in the mixin linked above for more information. There are examples in the [test suite's Rails models](https://github.com/RIPAGlobal/scimitar/tree/main/spec/apps/dummy/app/models), or for another example:

```ruby
class User < ActiveRecord::Base

  # The attributes in the SCIM section below include a reference to this
  # hypothesised 'groups' HABTM relationship. All of the other "leaf node"
  # Symbols - e.g. ":first_name", ":last_name" - are expected to be defined as
  # accessors e.g. via ActiveRecord and your related database table columns,
  # "attr_accessor" declarations, or bespoke "def foo"/"def foo=(value)". If a
  # write accessor is not present, the attribute will not be writable via SCIM.
  #
  has_and_belongs_to_many :groups

  # ===========================================================================
  # SCIM MIXIN AND REQUIRED METHODS
  # ===========================================================================
  #
  # All class methods shown below are mandatory unless otherwise commented.

  def self.scim_resource_type
    return Scimitar::Resources::User
  end

  def self.scim_attributes_map
    return {
      id:         :id,
      externalId: :scim_uid,
      userName:   :username,
      name:       {
        givenName:  :first_name,
        familyName: :last_name
      },
      emails: [
        {
          match: 'type',
          with:  'work',
          using: {
            value:   :work_email_address,
            primary: true
          }
        },
        {
          match: 'type',
          with:  'home',
          using: {
            value:   :home_email_address,
            primary: false
          }
        },
      ],
      phoneNumbers: [
        {
          match: 'type',
          with:  'work',
          using: {
            value:   :work_phone_number,
            primary: false
          }
        },
      ],

      # NB The 'groups' collection in a SCIM User resource is read-only, so
      #    we provide no ":find_with" key for looking up records for writing
      #    updates to the associated collection.
      #
      groups: [
        {
          list:  :groups,
          using: {
            value:   :id,
            display: :display_name
          }
        }
      ],
      active: :is_active
    }
  end

  def self.scim_mutable_attributes
    return nil
  end

  def self.scim_queryable_attributes
    return {
      givenName:        { column: :first_name },
      familyName:       { column: :last_name },
      emails:           { column: :work_email_address },
      "groups":         { column: MockGroup.arel_table[:id] },
      "groups.value":   { column: MockGroup.arel_table[:id] },
    }
  end

  # Optional but recommended.
  #
  def self.scim_timestamps_map
    {
      created:      :created_at,
      lastModified: :updated_at
    }
  end

  # If you omit any mandatory declarations, you'll get an exception raised by
  # this inclusion which tells you which method(s) need(s) to be added.
  #
  include Scimitar::Resources::Mixin
end
```

### Controllers

#### ActiveRecord

If you use ActiveRecord, your controllers can potentially be extremely simple by subclassing [`Scimitar::ActiveRecordBackedResourcesController`](https://www.rubydoc.info/gems/scimitar/Scimitar/ActiveRecordBackedResourcesController) - at a minimum:

```ruby
module Scim
  class UsersController < Scimitar::ActiveRecordBackedResourcesController

    skip_before_action :verify_authenticity_token

    protected

      def storage_class
        User
      end

      def storage_scope
        User.all # Or e.g. "User.where(is_deleted: false)" - whatever base scope you require
      end

  end
end
```

All data-layer actions are taken via `#find` or `#save!`, with exceptions such as `ActiveRecord::RecordNotFound`, `ActiveRecord::RecordInvalid` or generalised SCIM exceptions handled by various superclasses. For a real Rails example of this, see the [test suite's controllers](https://github.com/RIPAGlobal/scimitar/tree/main/spec/apps/dummy/app/controllers) which are invoked via its [routing declarations](https://github.com/RIPAGlobal/scimitar/blob/main/spec/apps/dummy/config/routes.rb).

#### Queries & Optimizations

The scope can be optimized to eager load the data exposed by the SCIM interface, i.e.:

```ruby
      def storage_scope
        User.eager_load(:groups)
      end
```

In cases where you have references to related columns in your `scim_queryable_attributes`, your `storage_scope` must join the relation:

```ruby
      def storage_scope
        User.left_join(:groups)
      end
```

#### Other source types

If you do _not_ use ActiveRecord to store data, or if you have very esoteric read-write requirements, you can subclass [`Scimigar::ResourcesController`](https://www.rubydoc.info/gems/scimitar/Scimitar/ResourcesController) in a manner similar to this:

```ruby
class UsersController < Scimitar::ResourcesController

  # SCIM clients don't use Rails CSRF tokens.
  #
  skip_before_action :verify_authenticity_token

  # If you have any filters you need to run BEFORE authentication done in
  # the superclass (typically set up in config/initializers/scimitar.rb),
  # then use "prepend_before_filter to declare these - else Scimitar's
  # own authorisation before-action filter would always run first.

  def index
    # There's a degree of heavy lifting for arbitrary storage engines.
    query = if params[:filter].present?
      attribute_map = User.new.scim_queryable_attributes() # Note use of *instance* method
      parser        = Scimitar::Lists::QueryParser.new(attribute_map)

      parser.parse(params[:filter])
      # Then use 'parser' to read e.g. #tree or #rpn and turn this into a
      # query object for your storage engine. With ActiveRecord, you could
      # just do: parser.to_activerecord_query(base_scope)
    else
      # Return a query object for 'all results' (e.g. User.all).
    end

    # Assuming the 'query' object above had ActiveRecord-like semantics,
    # you'd create a Scimitar::Lists::Count object with total count filled in
    # via #scim_pagination_info and obtain a page of results with something
    # like the code shown below.
    pagination_info = scim_pagination_info(query.count())
    page_of_results = query.offset(pagination_info.offset).limit(pagination_info.limit).to_a

    super(pagination_info, page_of_results) do | record |
      # Return each instance as a SCIM object, e.g. via Scimitar::Resources::Mixin#to_scim
      record.to_scim(location: url_for(action: :show, id: record.id))
    end
  end

  def show
    super do |user_id|
      user = find_user(user_id)
      # Evaluate to the record as a SCIM object, e.g. via Scimitar::Resources::Mixin#to_scim
      user.to_scim(location: url_for(action: :show, id: user_id))
    end
  end

  def create
    super do |scim_resource|
      # Create an instance based on the Scimitar::Resources::User in
      # "scim_resource" (or whatever your ::storage_class() defines via its
      # ::scim_resource_type class method).
      record = self.storage_class().new
      record.from_scim!(scim_hash: scim_resource.as_json())
      self.save!(record)
      # Evaluate to the record as a SCIM object (or do that via "self.save!")
      user.to_scim(location: url_for(action: :show, id: record.id))
    end
  end

  def replace
    super do |record_id, scim_resource|
      # Fully update an instance based on the Scimitar::Resources::User in
      # "scim_resource" (or whatever your ::storage_class() defines via its
      # ::scim_resource_type class method). For example:
      record = self.find_record(record_id)
      record.from_scim!(scim_hash: scim_resource.as_json())
      self.save!(record)
      # Evaluate to the record as a SCIM object (or do that via "self.save!")
      user.to_scim(location: url_for(action: :show, id: record_id))
    end
  end

  def update
    super do |record_id, patch_hash|
      # Partially update an instance based on the PATCH payload *Hash* given
      # in "patch_hash" (note that unlike the "scim_resource" parameter given
      # to blocks in #create or #replace, this is *not* a high-level object).
      record = self.find_record(record_id)
      record.from_scim_patch!(patch_hash: patch_hash)
      self.save!(record)
      # Evaluate to the record as a SCIM object (or do that via "self.save!")
      user.to_scim(location: url_for(action: :show, id: record_id))
    end
  end

  def destroy
    super do |user_id|
      user = find_user(user_id)
      user.delete
    end
  end

  protected

    # The class including Scimitar::Resources::Mixin which declares mappings
    # to the entity you return in #resource_type.
    #
    def storage_class
      User
    end

    # Find your user. The +id+ parameter is one of YOUR identifiers, which
    # are returned in "id" fields in JSON responses via SCIM schema. If the
    # remote caller (client) doesn't want to remember your IDs and hold a
    # mapping to their IDs, then they do an index with filter on their own
    # "externalId" value and retrieve your "id" from that response.
    #
    def find_user(id)
      # Find records by your ID here.
    end

    # Persist 'user' - for example, if we *were* using ActiveRecord...
    #
    def save!(user)
      user.save!
    rescue ActiveRecord::RecordInvalid => exception
      raise Scimitar::ResourceInvalidError.new(record.errors.full_messages.join('; '))
    end

end

```

Note that the [`Scimitar::ApplicationController` parent class](https://www.rubydoc.info/gems/scimitar/Scimitar/ApplicationController) of `Scimitar::ResourcesController` has a few methods to help with handling exceptions and rendering them as SCIM responses; for example, if a resource were not found by ID, you might wish to use [`Scimitar::ApplicationController#handle_resource_not_found`](https://github.com/RIPAGlobal/scimitar/blob/v1.0.3/app/controllers/scimitar/application_controller.rb#L22).

### Extension schema

You can extend schema with custom data by defining an extension class and calling `::extend_schema` on the SCIM resource class to which the extension applies. These extension classes:

* Must subclass `Scimitar::Schema::Base`
* Must call `super` in `def initialize`, providing data as shown in the example below
* Must define class methods for `::id` and `::scim_attributes`

The `::id` class method defines a unique schema ID that is used to namespace payloads or paths in JSON responses describing extended resources, JSON payloads creating them or PATCH paths modifying them. The SCIM RFCs would refer to this as the URN. For example, we might choose to use the [RFC-defined User extension schema](https://tools.ietf.org/html/rfc7643#section-4.3) to define a couple of extra fields our User model happens to support:

```ruby
class UserEnterpriseExtension < Scimitar::Schema::Base
  def initialize(options = {})
    super(
      name:            'ExtendedUser',
      description:     'Enterprise extension for a User',
      id:              self.class.id,
      scim_attributes: self.class.scim_attributes
    )
  end

  def self.id
    'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User'
  end

  def self.scim_attributes
    [
      Scimitar::Schema::Attribute.new(name: 'organization', type: 'string'),
      Scimitar::Schema::Attribute.new(name: 'department',   type: 'string')
    ]
  end
end
```

...with the `super` call providing your choice of `name` and `description`, but also always providing `id` and `scim_attributes` as shown above. The class name chosen here is just an example and the class can be put inside any level of wrapping namespaces you choose - it's *your* class that can be named however you like. The extension class is then applied to the SCIM User resource _globally in your application_ by calling:

```ruby
Scimitar::Resources::User.extend_schema(UserEnterpriseExtension)
```

This is often done in `config/initializers/scimitar.rb` to help make it very clear that extensions are globally available and remove the risk of SCIM resources somehow being referenced before schema extensions have been applied.

In `def self.scim_attributes_map` in the underlying data model, add any new fields - `organization` and `department` in this example - to map them to whatever the equivalent data model attributes are, just as you would do with any other resource fields. These are declared without any special nesting - for example:

```ruby
def self.scim_attributes_map
  return {
    id:           :id,
    externalId:   :scim_uid,
    userName:     :username,
    # ...etc...
    organization: :company,
    department:   :team
  }
end
```

Whatever you provide in the `::id` method in your extension class will be used as a namespace in JSON data. This means that, for example, a SCIM representation of the above resource would look something like this:

```json
{
  "schemas": [
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"
  ],
  "id": "2819c223-7f76-453a-413861904646",
  "externalId": "701984",
  "userName": "bjensen@example.com",
  // ...

  "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User": {
    "organization": "Corporation Incorporated",
    "department": "Marketing",
  },
  // ...
}
```

...and likewise, creation via `POST` would require the same nesting if a caller wanted to create a resource instance with those extended properties set (and RFC-compliant consumers of your SCIM API should already be doing this). For `PATCH` operations, [the `path` uses a _colon_ to separate the ID/URN part from the path](https://tools.ietf.org/html/rfc7644#section-3.10) rather than just using a dot as you might expect from the JSON nesting above:

```json
{
  "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
  "Operations": [
    {
      "op": "replace",
      "path": "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:organization",
      "value": "Sales"
    }
  ]
}
```

Resource extensions can provide any fields you choose, under any ID/URN you choose, to either RFC-described resources or entirely custom SCIM resources. There are no hard-coded assumptions or other "magic" that might require you to only extend RFC-described resources with RFC-described extensions. Of course, if you use custom resources or custom extensions that are not described by the SCIM RFCs, then the SCIM API you provide may only work with custom-written API callers that are aware of your bespoke resources and/or extensions.

Extensions can also contain complex attributes such as groups. For instance, if you want the ability to write to groups from the User resource perspective (since 'groups' collection in a SCIM User resource is read-only), you can add one attribute to your extension like this:

```ruby
Scimitar::Schema::Attribute.new(name: "userGroups", multiValued: true, complexType: Scimitar::ComplexTypes::ReferenceGroup, mutability: "writeOnly"),
```

Then map it in your `scim_attributes_map`:

```ruby
  userGroups: [
    {
      list: :groups,
      find_with: ->(value) { Group.find(value["value"]) },
      using: {
        value:   :id,
        display: :name
      }
    }
  ]
```

And write to it like this:

```json
{
  "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
  "Operations": [
    {
      "op": "replace",
      "path": "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User:userGroups",
      "value": [{ "value": "1" }]
    }
  ]
}
```

## Security

One vital feature of SCIM is its authorisation and security model. The best resource I've found to describe this in any detail is [section 2 of the protocol RFC, 7644](https://tools.ietf.org/html/rfc7644#section-2).

Often, you'll find that bearer tokens are in use by SCIM API consumers, but the way in which this is used by that consumer in practice can vary a great deal. For example, suppose a corporation uses Microsoft Azure Active Directory to maintain a master database of employee details. Azure lets administrators [connect to SCIM endpoints](https://docs.microsoft.com/en-us/azure/active-directory/app-provisioning/how-provisioning-works) for services that this corporation might use. In all cases, bearer tokens are used.

* When the third party integration builds an app that it gets hosted in the Azure Marketplace, the token is obtained via full OAuth flow of some kind - the enterprise corporation would sign into your app by some OAuth UI mechanism you provide, which leads to a Bearer token being issued. Thereafter, the Azure system would quote this back to you in API calls via the `Authorization` HTTP header.

* If you are providing SCIM services as part of some wider service offering it might not make sense to go to the trouble of adding all the extra features and requirements for Marketplace inclusion. Fortunately, Microsoft support [addition of 'user-defined' enterprise "app" integrations](https://docs.microsoft.com/en-us/azure/active-directory/app-provisioning/use-scim-to-provision-users-and-groups#integrate-your-scim-endpoint-with-the-aad-scim-client) in Azure, so the administrator can set up and 'provision' your SCIM API endpoint. In _this_ case, the bearer token is just some string that you generate which they paste into the Azure AD UI. Clearly, then, this amounts to little more than a glorified password, but you can take steps to make sure that it's long, unguessable and potentially be some encrypted/encoded structure that allows you to make additional security checks on "your side" when you unpack the token as part of API request handling.

* HTTPS is obviously a given here and localhost integration during development is difficult; perhaps search around for things like POSTman collections to assist with development testing. Scimitar has a reasonably comprehensive internal test suite but it's only as good as the accuracy and reliability of the subclass code you write to "bridge the gap" between SCIM schema and actions, and your User/Group equivalent records and the operations you perform upon them. Microsoft provide [additional information](https://techcommunity.microsoft.com/t5/identity-standards-blog/provisioning-with-scim-design-build-and-test-your-scim-endpoint/ba-p/1204883) to help guide service provider implementors with best practice.



## Limitations

### Specification versus implementation

* The `name` complex type of a User has `givenName` and `familyName` fields which [the RFC 7643 core schema](https://tools.ietf.org/html/rfc7643#section-8.7.1) describes as optional. Scimitar marks these as required, in the belief that most user synchronisation scenarios between clients and a Scimitar-based provider would require at least those names for basic user management on the provider side, in conjunction with the in-spec-required `userName` field. That's only if the whole `name` type is given at all - at the top level, this itself remains optional per spec, but if you're going to bother specifying names at all, Scimitar wants at least those two pieces of data.

* Several complex types for User contain the same set of `value`, `display`, `type` and `primary` fields, all used in synonymous ways.

  - The `value` field - which is e.g. an e-mail address or phone number - is described as optional by [the RFC 7643 core schema](https://tools.ietf.org/html/rfc7643#section-8.7.1), also using "SHOULD" rather than "MUST" in field descriptions elsewhere. Scimitar marks this as required by default, since there's not much point being sent (say) an e-mail section which has entries that don't provide the e-mail address. Some services might send `null` values here regardless so, if you need to be able to accept such data, you can set [engine configuration option `optional_value_fields_required`](https://github.com/RIPAGlobal/scimitar/blob/main/config/initializers/scimitar.rb) to `false`.

  - The schema _descriptions_ for `display` declare that the field is something optionally sent by the service provider and state clearly that it is read-only - yet the formal schema declares it `readWrite`. Scimitar marks it as read-only.

* The `displayName` of a Group is described in [RFC 7643 section 4.2](https://tools.ietf.org/html/rfc7643#section-4.2) and in the free-text schema `description` field as required, but the schema nonetheless states `"required" : false` in the formal definition. We consider this to be an error and mark the property as `"required" : true`.

* In the `members` section of a [`Group` in the RFC 7643 core schema](https://tools.ietf.org/html/rfc7643#page-69), any member's `value` is noted as _not_ required but [the RFC also says](https://tools.ietf.org/html/rfc7643#section-4.2) "Service providers MAY require clients to provide a non-empty value by setting the "required" attribute characteristic of a sub-attribute of the "members" attribute in the "Group" resource schema". Scimitar does this. The `value` field would contain the `id` of a SCIM resource, which is the primary key on "our side" as a service provider. Just as we must store `externalId` values to maintain a mapping on "our side", we in turn _do_ require clients to provide our ID in group member lists via the `value` field.

* While the gem attempts to support difficult/complex filter strings via incorporating code and ideas in [SCIM Query Filter Parser](https://github.com/ingydotnet/scim-query-filter-parser-rb), it is possible that ActiveRecord / Rails precedence on some query operations in complex cases might not exactly match the SCIM specification. Please do submit a bug report if you encounter this. You may also wish to view [`query_parser_spec.rb`](https://github.com/RIPAGlobal/scimitar/blob/main/spec/models/scimitar/lists/query_parser_spec.rb) to get an idea of the tested examples - more interesting test cases are in the "`context 'with complex cases' do`" section.

* Group resource examples show the `members` array including field `display`, but this is not in the [formal schema](https://tools.ietf.org/html/rfc7643#page-69); Scimitar includes it in the Group definition.

* `POST` actions with only a subset of attributes specified treat missing attributes "to be cleared" for anything that's mapped for the target model. If you have defaults established at instantiation rather than (say) before-validation, you'll need to override `Scimitar::ActiveRecordBackedResourcesController#create` (if using that controller as a base class) as normally the controller just instantiates a model, applies _all_ attributes (with any mapped attribute values without an inbound value set to `nil`), then saves the record. This might cause default values to be overwritten. For consistency, `PUT` operations apply the same behaviour. The decision on this optional specification aspect is in part constrained by the difficulties of implementing `PATCH`.

* [RFC 7644 indicates](https://tools.ietf.org/html/rfc7644#page-35) that a resource might only return its core schema in the `schemas` attribute if it was created without any extension fields used. Only if e.g. a subsequent `PATCH` operation added data provided by extension schema, would that extension also appear in `schemas`. This behaviour is extremely difficult to implement and Scimitar does not try - it will always return a resource's core schema and any/all defined extension schemas in the `schemas` array at all times.

If you believe choices made in this section may be incorrect, please [create a GitHub issue](https://github.com/RIPAGlobal/scimitar/issues/new) describing the problem.

### Omissions

* Bulk operations are not supported.

* List ("index") endpoint [filters in SCIM](https://tools.ietf.org/html/rfc7644#section-3.4.2.2) are _extremely_ complicated. There is a syntax for specifying equals, not-equals, precedence through parentheses and things like "and"/"or"/"not" along the lines of "attribute operator value", which Scimitar supports to a reasonably comprehensive degree but with some limitations discussed shortly. That aside, it isn't at all clear what some of the [examples in the RFC](https://tools.ietf.org/html/rfc7644#page-23) are even meant to mean. Consider:

  - `filter=userType eq "Employee" and (emails co "example.com" or emails.value co "example.org")`

  It's very strange just specifying `emails co...`, since this is an Array which contains complex types. Is the filter there meant to try and match every attribute of the nested types in all array entries? I.e. if `type` happened to contain `example.com`, is that meant to match? It's strongly implied, because the next part of the filter specifically says `emails.value`. Again, we have to reach a little and assume that `emails.value` means "in _any_ of the objects in the `emails` Array, match all things where `value` contains `example.org`. It seems likely that this is a specification error and both of the specifiers should be `emails.value`.

  Adding even more complexity - the specification shows filters _which include filters within them_. In the same way that PATCH operations use paths to identify attributes not just by name, but by filter matches within collections - e.g. `emails[type eq "work"]`, for all e-mail objects inside the `emails` array with a `type` attribute that has a value of `work`) - so also can a filter _contain a filter_, which isn't supported. So, this [example from the RFC](https://tools.ietf.org/html/rfc7644#page-23) is not supported by Scimitar:

  - `filter=userType eq "Employee" and emails[type eq "work" and value co "@example.com"]`

  Another filter shows a potential workaround:

  - `filter=userType eq "Employee" and (emails.type eq "work")`

  ...which is just a match on `emails.type`, so if you have a queryable attribute mapping defined for `emails.type`, that would become queryable. Likewise, you could rewrite the more complex prior example thus:

  - `filter=userType eq "Employee" and emails.type eq "work" and emails.value co "@example.com"`

  ...so adding a mapping for `emails.value` would then allow a database query to be constructed.

* Currently filtering for lists is always matched case-insensitive regardless of schema declarations that might indicate otherwise, for `eq`, `ne`, `co`, `sw` and `ew` operators; for greater/less-thank style filters, case is maintained with simple `>`, `<` etc. database operations in use. The standard Group and User schema have `caseExact` set to `false` for just about anything readily queryable, so this hopefully would only ever potentially be an issue for custom schema.

* As an exception to the above, attributes `id`, `externalId` and `meta.*` are matched case-sensitive. Filters that use `eq` on such attributes will end up a comparison using `=` rather than e.g. `ILIKE` (arising from https://github.com/RIPAGlobal/scimitar/issues/36).

* The `PATCH` mechanism is supported, but where filters are included, only a single "attribute eq value" is permitted - no other operators or combinations. For example, a work e-mail address's value could be replaced by a PATCH patch of `emails[type eq "work"].value`. For in-path filters such as this, other operators such as `ne` are not supported; combinations with "and"/"or" are not supported; negation with "not" is not supported.

If you would like to see something listed in the session implemented, please [create a GitHub issue](https://github.com/RIPAGlobal/scimitar/issues/new) asking for it to be implemented, or if possible, implement the feature and send a Pull Request.



## Development

Install Ruby dependencies first:

```
bundle install
```

### Tests

You will need to have PostgreSQL running. This database is chosen for tests to prove case-insensitive behaviour via detection of ILIKE in generated queries. Using SQLite would have resulted in a more conceptually self-contained test suite, but SQLite is case-insensitive by default and uses "LIKE" either way, making it hard to "see" if the query system is doing the right thing.

After `bundle install` and with PostgreSQL up, set up the test database with:

```shell
pushd spec/apps/dummy
RAILS_ENV=test bundle exec rails db:drop db:create db:migrate
popd
```

...and thereafter, run tests with:

```
bundle exec rspec
```

You can get an idea of arising test coverage by opening `coverage/index.html` in your preferred web browser.

### Internal documentation

Locally generated RDoc HTML seems to contain a more comprehensive and inter-linked set of pages than those available from `rubydoc.info`. You can (re)generate the internal [`rdoc` documentation](https://ruby-doc.org/stdlib-2.4.1/libdoc/rdoc/rdoc/RDoc/Markup.html#label-Supported+Formats) with:

```shell
bundle exec rake rerdoc
```

...yes, that's `rerdoc` - Re-R-Doc - then open `docs/rdoc/index.html`.
