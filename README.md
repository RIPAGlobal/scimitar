# Scimitar

[![License](https://img.shields.io/badge/license-mit-blue.svg)](https://opensource.org/licenses/MIT)

Comprehensive SCIM v2 support for Users and Groups in Ruby On Rails.



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

Scimitar borrow heavily - to the point of cut-and-paste - from:

* [Scimitar](https://github.com/Cisco-AMP/scimitar) for the Rails controllers and resource-agnostic subclassing approach that makes supporting User and/or Group, along with custom resource types if you need them, quite easy.
* [ScimRails](https://github.com/lessonly/scim_rails) for the bearer token support, 'index' actions and filter support.
* [Scim::Kit](https://github.com/xlgmokha/scim-kit) as a handy, formalised way to convert to/from SCIM JSON schema and your own records (be they persisted via ActiveRecord or any other means).

All three are provided under the MIT license. Scimitar is too.



## Usage

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

One IMHO under-discussed feature of SCIM is the authorisation and security model. The best resource I've found to describe this in any detail is [section 2 of the protocol RFC, 7644](https://tools.ietf.org/html/rfc7644#section-2). Often, you'll find that bearer tokens are in use by SCIM API consumers.

As an example, suppose a corporation uses Microsoft Azure Active Directory to maintain a master database of employee details. Azure lets administrators [connect to SCIM endpoints]() for services that this corporation might use. In all cases, bearer tokens are used.

* When the third party integration builds an app that it gets hosted in the Azure Marketplace, the token is obtained via full OAuth flow of some kind - the enterprise corporation would sign into your app by some OAuth UI mechanism you provide, which leads to a Bearer token being issued. Thereafter, the Azure system would quote this back to you in API calls via the `Authorization` HTTP header.

* If you are providing SCIM services as part of some wider service offering it might not make sense to go to the trouble of adding all the extra features and requirements for Marketplace inclusion. Fortunately, Microsoft support addition of 'user-defined' enterprise "app" integrations in Azure, so the administrator can set up and 'provision' your SCIM API endpoint. In _this_ case, the bearer token is just some string that you generate which they paste into the Azure AD UI. Clearly, then, this amounts to little more than a glorified password, but you can take steps to make sure that it's long, unguessable and potentially be some encrypted/encoded structure that allows you to make additional security checks on "your side" when you unpack the token as part of API request handling.

* HTTPS is obviously a given here and localhost integration during development is difficult; perhaps search around for things like POSTman collections to assist with development testing. Scimitar has a reasonably comprehensive internal test suite but it's only as good as the accuracy and reliability of the subclass code you write to "bridge the gap" between SCIM schema and actions, and your User/Group equivalent records and the operations you perform upon them.




LINKS FOR
https://techcommunity.microsoft.com/t5/identity-standards-blog/provisioning-with-scim-design-build-and-test-your-scim-endpoint/ba-p/1204883
https://docs.microsoft.com/en-us/azure/active-directory/app-provisioning/how-provisioning-works
https://docs.microsoft.com/en-us/azure/active-directory/app-provisioning/use-scim-to-provision-users-and-groups#integrate-your-scim-endpoint-with-the-aad-scim-client



## Development

Install dependencies first:

```
bundle install
```



## Tests

The tests use [RSpec](http://rspec.info):

```shell
bundle exec rspec
```



## Internal documentation

Regenerate the internal [`rdoc` documentation](https://ruby-doc.org/stdlib-2.4.1/libdoc/rdoc/rdoc/RDoc/Markup.html#label-Supported+Formats) with:

```shell
bundle exec rake rerdoc
```

...yes, that's `rerdoc` - Re-R-Doc.
