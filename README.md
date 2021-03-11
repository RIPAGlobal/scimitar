# Scimitar

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


Some of the stuff to do here:

* Setting up what authentication method you use
* Building an example subclass to do basic User operations
* How to map to/from your own User records and a Scimitar::User
* Likewise, groups
* Bulk operations and filters


Scimitar neither enforces nor presumes any kind of encoding for bearer tokens. You can use anything you like, including encoding/encrypting JWTs if you so wish - https://rubygems.org/gems/jwt may be useful. The way in which a client might integrate with your SCIM service varies by client and you will have to check documentation to see how a token gets conveyed to that client in the first place (e.g. a full OAuth flow with your application, or just a static token generated in some UI which an administrator copies and pastes into their client's SCIM configuration UI).




### Routes

For each resource you support, add these lines to your `routes.rb`:

```ruby
namespace :scim do
  mount Scimitar::Engine, at: '/'

  get    'Users',     to: 'users#index'
  get    'Users/:id', to: 'users#show'
  post   'Users',     to: 'users#create'
  put    'Users/:id', to: 'users#update'
  patch  'Users/:id', to: 'users#update'
  delete 'Users/:id', to: 'users#destroy'
end
```

...where `patch` is intentionally routed to `#update`, which is expected to handle both replace-like semantics (`put`) and update-partially semantics (`patch`). You can change the routing if you prefer, but you'll need to do more custom work in any controllers as the above is the out-of-box expectation for the various Scimitar base controller classes.

All routes then will be available at `https://.../scim/...`.

### Controllers

If you do _not_ use ActiveRecord to store data, or if you have very esoteric read-write requirements, you can subclass `ScimEngine::ResourcesController` in a manner similar to this:

```ruby
module Scim

  # SCIM clients don't use Rails CSRF tokens.
  #
  skip_before_action :verify_authenticity_token

  class UsersController < ScimEngine::ResourcesController

    # If you have any filters you need to run BEFORE authentication done in
    # the superclass (typically set up in config/initializers/scimitar.rb),
    # then use "prepend_before_filter to declare these - else Scimitar's
    # own authorisation before-action filter would always run first.

    def index
      super(user_scope) do | user |
        # Return each instance as a SCIM object, e.g. via Scimitar::Resources::Mixin#to_scim
        user.to_scim(location: url_for(action: :show, id: user.id))
      end
    end

    def show
      super do |user_id|
        user = find_user(user_id)
        # Return the instance as a SCIM object, e.g. via Scimitar::Resources::Mixin#to_scim
        user.to_scim(location: url_for(action: :show, id: user_id))
      end
    end

    def create
      super(&method(:save))
    end

    def update
      super(&method(:save))
    end

    def destroy
      super do |user_id|
        user = find_user(user_id)
        user.delete
      end
    end

    protected

      def save(scim_user, operation)

        # You might need to enclose the code below in a transaction of some
        # sort, depending on your storage engine's behaviour. It is definitely
        # needed for ActiveRecord.
        #
        case operation
          when :create
            record = User.new
            # Fill in all data from the SCIM payload, e.g. via Scimitar::Resources::Mixin#from_scim!
            record.from_scim!(scim_hash: scim_resource.as_json)

          when :replace
            record = find_record(scim_resource['id'])
            # Replace all attributes from the SCIM payload, e.g. via Scimitar::Resources::Mixin#from_scim!
            record.from_scim!(scim_hash: scim_resource.as_json)

          when :patch
            record = find_record(scim_resource['id'])
            # Update some attributes from the SCIM patch data, e.g. via Scimitar::Resources::Mixin#from_scim_patch!
            record.from_scim_patch!(patch_hash: scim_resource.as_json)
        end

        # ...and persist 'record'. You should always try to store the
        # 'externalId' value.
      rescue ActiveRecord::RecordInvalid => exception
        # Map the enternal errors to a ScimEngine error.
        raise ScimEngine::ResourceInvalidError.new(...error message here...)
      end

      # The class including Scimitar::Resources::Mixin which declares mappings
      # to the entity you return in #resource_type.
      #
      def storage_class
        User
      end

      # Return an index (list) ActiveRecord::Relation scope for User records.
      #
      def user_scope
        # Return a User scope here - e.g. User.all, Company.users...
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

  end
end

```

Note that the `Scimitar::ApplicationController` parent class of `Scimitar::ResourcesController` has a few methods to help with handling exceptions and rendering them as SCIM responses; for example, if a resource were not found by ID, you might wish to call `Scimitar::ApplicationController#handle_resource_not_found`. If you use ActiveRecord, though, you can choose a more advanced subclass and all of that gets handled for you:

```ruby
module Scim
  class MockUsersController < Scimitar::ActiveRecordBackedResourcesController

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

In the simplest case - that's it! All actions are taken via `#find` or `#save!`, with things like `ActiveRecord::RecordNotFound` or generalised SCIM errors handled by the various superclasses.



```
GREAT

BIG

TO

DO

LIST

OF

STUFF

THAT

NEEDS

TO

GO

HERE

:-)

(I'll know it once I've built it)
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

* Several complex types for User contain the same set of `value`, `display`, `type` and `primary` fields, all used in synonymous ways. The `value` field - which is e.g. an e-mail address or phone number - is described as optional by [the RFC 7643 core schema](https://tools.ietf.org/html/rfc7643#section-8.7.1), also using "SHOULD" rather than "MUST" in field descriptions elsewhere. Scimitar marks this as required; there's no point being sent (say) an e-mail section which has entries that don't provide the e-mail address! The schema descriptions for `display` also note that this is something optionally sent by the service provider and says clearly that it is read-only - yet the schema declares it `readWrite`. Scimitar marks it as read-only in its schema.

* The `displayName` of a Group is described in [RFC 7643 section 4.2](https://tools.ietf.org/html/rfc7643#section-4.2) and in the free-text schema `description` field as required, but the schema nonetheless states `"required" : false` in the formal definition. We consider this to be an error and mark the property as `"required" : true`.

* In the `members` section of a [`Group` in the RFC 7643 core schema](https://tools.ietf.org/html/rfc7643#page-69), any member's `value` is noted as _not_ required but [the RFC also says](https://tools.ietf.org/html/rfc7643#section-4.2) "Service providers MAY require clients to provide a non-empty value by setting the "required" attribute characteristic of a sub-attribute of the "members" attribute in the "Group" resource schema". Scimitar does this. The `value` field would contain the `id` of a SCIM resource, which is the primary key on "our side" as a service provider. Just as we must store `externalId` values to maintain a mapping on "our side", we in turn _do_ require clients to provide our ID in group member lists via the `value` field.

* While the gem attempts to support difficult/complex filter strings via incorporating code and ideas in [SCIM Query Filter Parser](https://github.com/ingydotnet/scim-query-filter-parser-rb), it is possible that ActiveRecord / Rails precedence on some query operations in complex cases might not exactly match the SCIM specification. Please do submit a bug report if you encounter this. You may also wish to view [`query_parser_spec.rb`](https://github.com/RIPGlobal/scimitar/blob/main/spec/models/scimitar/lists/query_parser_spec.rb) to get an idea of the tested examples - more interesting test cases are in the "`context 'with complex cases' do`" section.

### Omissions

* Only whole-resource `PUT` is supported for updates, not the complicated `PATCH` mechanism. The mandatory former maps very closely to Rails behaviour while the optional latter would require very extensive extra code, especially around multiple operation types and `path` handling, with its filter-like strings.



## Development

Install dependencies first:

```
bundle install
```

### Tests

The tests use [RSpec](http://rspec.info) and require SQLite to be installed on your system. After `bundle install`, set up the test database with:

```shell
pushd spec/apps/dummy
RAILS_ENV=test bundle exec rails db:drop db:create db:migrate
popd
```

...and thereafter, run tests with:

```
bundle exec rspec
```

### Internal documentation

Regenerate the internal [`rdoc` documentation](https://ruby-doc.org/stdlib-2.4.1/libdoc/rdoc/rdoc/RDoc/Markup.html#label-Supported+Formats) with:

```shell
bundle exec rake rerdoc
```

...yes, that's `rerdoc` - Re-R-Doc.
