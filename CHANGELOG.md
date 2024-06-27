# 2.8.0 (2024-06-13)

Features:

* Supports the [SCIM mechanism for requesting specific attributes](https://datatracker.ietf.org/doc/html/rfc7644#section-3.9) (noting however that schema ID URN prefixes are not supported; use only dotted attribute paths without such prefixes) - closes [89](https://github.com/RIPAGlobal/scimitar/issues/89) via [102](https://github.com/RIPAGlobal/scimitar/pull/102) and [127](https://github.com/RIPAGlobal/scimitar/pull/127) - thanks to `@xjunior`
* In a moment of déja vu from v2.7.3's Microsoft payload workarounds for [123](https://github.com/RIPAGlobal/scimitar/issues/123), handles a different kind of malformed filter sent by Microsoft Azure (Entra) in `GET` requests - implements [115](https://github.com/RIPAGlobal/scimitar/issues/115) requested by `@gsar` via [128](https://github.com/RIPAGlobal/scimitar/pull/128)
* Handles schema IDs (URNs) in filters of `GET` requests - implements [116](https://github.com/RIPAGlobal/scimitar/issues/116) requested by `@gsar` via [131](https://github.com/RIPAGlobal/scimitar/pull/131)

Fixes:

* Corrects schema for `name.givenName` and `name.familyName` in User, which previously specified these as required, but the SCIM specification says they are not - fixes [113](https://github.com/RIPAGlobal/scimitar/issues/113) reported by `@s-andringa` via [129](https://github.com/RIPAGlobal/scimitar/pull/129). If your code somehow _relies_ upon `name.givenName` and/or `name.familyName` being required in the User schema, you can patch this in your `config/initializers/scimitar.rb` file - for example:

    ```ruby
    Rails.application.config.to_prepare do
      Scimitar::Schema::Name.scim_attributes.find { |a| a.name == 'familyName' }.required = true
      Scimitar::Schema::Name.scim_attributes.find { |a| a.name == 'givenName'  }.required = true

      # ...
    end
    ```

# 2.7.3 (2024-06-11)

Features:

* As part of the above fix, schema ID handling was improved and extended with better test coverage. `PATCH` `add` and `replace` operations with `value` objects containing schema IDs both with or without attributes inline should now work reliably.

Fixes:

* Handles what I _think_ are technically malformed payloads from Azure (Entra), but since they seem unavoidable, it's important to handle them - should fix [123](https://github.com/RIPAGlobal/scimitar/issues/123) reported by `@eduardoborba`

# 2.7.2 (2024-03-27)

Fixes:

* The implementation of non-returned SCIM fields turned out to inadvertently prevent their subsequent update (so SCIM _updates_ to e.g. passwords would fail); fixed [105](https://github.com/RIPAGlobal/scimitar/issues/105) and (in passing) [6](https://github.com/RIPAGlobal/scimitar/issues/6), via [109](https://github.com/RIPAGlobal/scimitar/pull/109) - thanks to `@xjunior`
* The case-insensitive, String or Symbol access Hash class documented itself as preserving case but did not, reported in [98](https://github.com/RIPAGlobal/scimitar/issues/98), also via [109](https://github.com/RIPAGlobal/scimitar/pull/109) - thanks to `@s-andringa`

# 2.7.1 (2024-01-16)

Fixes:

* Some dependency chain gems have stopped supporting Ruby 2.7, so a `Gemfile.lock` for local development generated under Ruby 3 does not work under Ruby 2.7. Solved by removing `Gemfile.lock` entirely, so that an errant Nokogiri lock in `scimitar.gemspec` used previously as a workaround could also be removed.

# 2.7.0 (2024-01-15)

Warning:

* The default `type` value of `work` in the `address` complex type has been removed, in line with all other comparable complex types, via [87](https://github.com/RIPAGlobal/scimitar/issues/87) / [92](https://github.com/RIPAGlobal/scimitar/pull/92) - thanks to `@s-andringa`.
* **This is unlikely to break client code but there is a *small* chance of issues if you relied upon the default**. Please check your implementation if at all concerned. It doesn't seem risky enough to force a major version bump to comply with semantic versioning.

Features:

* Allow a block to be passed to `Scimitar::ActiveRecordBackedResourcesController#create`, `#update` and `#replace`. This behaves in a manner analogous to passing a block to `Scimitar::ActiveRecordBackedResourcesController#destroy`, wherein the block implementation becomes responsible for destroying the record the block is given; in the case of `#create`, `#update` and `#replace`, the block is passed the new or updated record and is responsible for persisting it.

Fixes:

* Fix for Microsoft SCIM Validator; pathless `replace` operations can use dot-path notation in the `value` section, via [69](https://github.com/RIPAGlobal/scimitar/pull/69) - thanks to `@wooly`
* Basic and token authentication blocks now operate in the context of the application's controller, via [88](https://github.com/RIPAGlobal/scimitar/pull/88) - thanks to `@tejanium`
* Exception handling for records during saving is improved and extensible, via [91](https://github.com/RIPAGlobal/scimitar/pull/91)

Maintenance:

* Bump local development Ruby to v3.3.0, including it in the test matrix and in effect creating "official" support for that Ruby version.

# 2.6.1 (2023-11-15)

* Always returns a `Content-Type` header with value `application/scim+json; charset=utf-8` in any response, since that's the only format the gem can write. Fixes [#59](https://github.com/RIPAGlobal/scimitar/issues/59).
* Uses the more common header name form of `WWW-Authenticate` rather than the Rack-like `WWW_AUTHENTICATE` in responses.

# 2.6.0 (2023-11-14)

Features:

* Schema location URLs are generated by the controller, making overrides simpler, via [#71](https://github.com/RIPAGlobal/scimitar/pull/71) - thanks to `@s-andringa`
* A block can be passed to `ActiveRecordBackedResourcesController#save!`, making it easier to override with custom behaviour since you won't have to worry about things like uniqueness constraint exceptions, via [#73](https://github.com/RIPAGlobal/scimitar/pull/73) - thanks to `@s-andringa`
* Those who want an invariant local testing setup can now consider using Docker via [#77](https://github.com/RIPAGlobal/scimitar/pull/77) - thanks to `@osingaatje`

Fixes:

* Multi-valued simple types are now correctly rendered via [74](https://github.com/RIPAGlobal/scimitar/pull/74) - thanks to `@s-andringa`
* Sensitive fields are no longer rendered (fixes [#56](https://github.com/RIPAGlobal/scimitar/issues/56) via [#80](https://github.com/RIPAGlobal/scimitar/pull/80) - thanks to `@kuldeepaggarwal`.

# 2.5.0 (2023-09-25)

Many thanks to `@xjunior`, who contributed a series of improvements and fixes present in this version. New features:

* Allow writable complex types in custom extensions via [#61](https://github.com/RIPAGlobal/scimitar/pull/61)
* Allow complex queries via table joins via [#62](https://github.com/RIPAGlobal/scimitar/pull/62)

Fixes:

* Much better error message raised if `PatchOp` misses operations in [#65](https://github.com/RIPAGlobal/scimitar/pull/65)
* Combined logical groups generate working queries with [#66](https://github.com/RIPAGlobal/scimitar/pull/66)

# 2.4.3 (2023-09-16)

* Maintenance release which merges a warning removal patch in [#54](https://github.com/RIPAGlobal/scimitar/pull/54) (thanks to `@sobrinho` for the contribution) via [#63](https://github.com/RIPAGlobal/scimitar/pull/63) and it is the changes in the latter which are brought into Scimitar V2 to keep a minimal overall diff between the V1 and V2.

# 2.4.2 (2023-03-21)

* Fix shortcoming in `Content-Type` header handling via [#51](https://github.com/RIPAGlobal/scimitar/pull/51). Thanks to `@Flixt` for the contribution.

# 2.4.1 (2023-03-02)

* Address https://github.com/RIPAGlobal/scimitar/issues/48 by adapting https://github.com/RIPAGlobal/scimitar/issues/49, so that extension schemas work properly. Missing documentation in `README.md` addressed. Thanks to `@bettysteger` and `@MorrisFreeman` for the contribution.

# 2.4.0 (2023-01-27)

* Address https://github.com/RIPAGlobal/scimitar/issues/43 - allows Microsoft-style payloads for removing Users from Groups, with a special case exception for hypothetical inbound SCIM calls originating from Salesforce software. For more details of the fix, please see https://github.com/RIPAGlobal/scimitar/pull/45.

# 2.3.0 (2023-01-17)

* Address https://github.com/RIPAGlobal/scimitar/issues/35. Declaring primary key in the ActiveRecord model would solve most of the problems described, but v2.2.0 did introduce a default order clause that would trip up a model with a different primary key name; this is now fixed. In any case, it may be possible to avoid declaring the primary key override in the model entirely if using Scimitar v2.3.0, should that be your wish. This is in effect an edge case new feature, which is why the gem's minor version has been bumped up.

# 2.2.0 (2023-01-13)

* Bump local development Ruby to v3.2.0, including it in the test matrix and in effect creating "official" support for that Ruby version.

# 2.1.3 (2023-01-09)

* Fix https://github.com/RIPAGlobal/scimitar/issues/36 - filters are case-sensitive for special cases of `id`, `externalId` and `meta.*` attributes. A model must still declare if and how these are searchable via its `::scim_queryable_attributes` implementation, just as with any other attribute.

# 2.1.2 (2023-01-09)

* Fix https://github.com/RIPAGlobal/scimitar/issues/37 - filters now correctly support case insensitive attribute names.

# 2.1.1 (2022-11-04)

* Merged https://github.com/RIPAGlobal/scimitar/pull/29, fixing an issue caused by an unhandled form of payload sent by Okta. Thanks to `@jasonopslevel` for the contribution.

# 2.1.0 (2022-07-14)

* Merged https://github.com/RIPAGlobal/scimitar/pull/17 (more detailed errors), https://github.com/RIPAGlobal/scimitar/pull/18 (`primary` attribute added to Address schema) and https://github.com/RIPAGlobal/scimitar/pull/19 (configurable required-or-optional `value` attributes in VDTP-derived types). Thanks for the contributions, `@pelted`!
* Noted closed PR https://github.com/RIPAGlobal/scimitar/pull/25 and implemented a configurable exception reporting hook for people who might want that kind of feature. See [engine configuration option `exception_reporter`](https://github.com/RIPAGlobal/scimitar/blob/main/config/initializers/scimitar.rb) for details.

# 2.0.2 (2022-06-15)

* Address https://github.com/RIPAGlobal/scimitar/issues/20 by better handling content type in requests:

  - Since https://github.com/MicrosoftDocs/azure-docs/issues/94189#issuecomment-1154227613 indicates that _no_ header is sent for `GET` methods while a correct header is sent for others; that is inline with the RFC and we should handle a lack of content type in the `GET` case. This was not the case in Scimitar v2.0.1 and earlier.
  - Ultimately we must expect attackers to send junk data in attempts to find vulnerabilities in JSON parsing, so the header presence can't really be trusted and the JSON parser must simply be robust. As a result, this patch version of the gem will assume an `application/scim+json` content type for _any_ inbound request that specifies no other type, regardless of HTTP method used. Requests are only rejected if a `Content-Type` header explicitly states that the content is of some unsupported type.

# 2.0.1 (2022-04-20)

* Merges https://github.com/RIPAGlobal/scimitar/pull/15 from `AbeerKhakwani`, fixing an issue with AD and the Meta object.

# 2.0.0 (2022-03-04)

* Requires Rails 7. Supports Ruby 3, but still works on 2.7.

## Upgrading from Scimitar 1.x.y

* Your `config/initializers/scimitar.rb` might need to be enclosed within a `Rails.application.config.to_prepare do...` block to avoid `NameError: uninitialized constant...` exceptions arising due to autoloader problems:

    ```ruby
    Rails.application.config.to_prepare do
      Scimitar.engine_configuration = Scimitar::EngineConfiguration.new({
        # ...
      end
    end
    ```

* If you use `Scimitar::Errors#add_errors_from_hash`, note that the previously-unnamed first parameter is now explicitly named `errors_hash`. This avoids potential ambiguity and confusion/errors with Ruby 3's more strict rules for named parameter and hash mixtures in both method definitions and method calls. For example:

    ```ruby
    # Old code...
    user.add_errors_from_hash(key: 'some key')
    # ...becomes:
    user.add_errors_from_hash(errors_hash: {key: 'some key'})

    # Old code...
    user.add_errors_from_hash({key: 'some key'}, prefix: 'some prefix')
    # ...becomes:
    user.add_errors_from_hash(errors_hash: {key: 'some key'}, prefix: 'some prefix')
    ```



# 1.3.1 (2022-11-04)

* Back-ports features from v2.1.1 for Rails 6 users.

# 1.3.0 (2022-07-14)

* Back-ports features from v2.1.0 for Rails 6 users.

# 1.2.1 (2022-06-15)

* Back-ports fixes from v2.0.1 and v2.0.2 for Rails 6 users.

# 1.2.0 (2021-09-27)

* Updated for RIPA branding.
* Ruby and gem version maintenance updates.

# 1.1.0 (2021-09-15)

* Implement case insensitivity for attributes (fixes [issue #7](https://github.com/RIPAGlobal/scimitar/issues/7)).

# 1.0.3 (2020-03-24)

* More robust path filter parsing for `PATCH` operations; previously, a path filter such as `value eq "Something With Spaces"` would have been rejected.

# 1.0.2 (2020-03-24)

* Add Travis support for CI.
* Adjust `scimitar.gemspec` a bit more for CI and now that we're public in RubyGems, with a `Gemfile.lock` bump on Scimitar itself (overlooked in 1.0.1).

# 1.0.1 (2020-03-24)

* Added source code link to `scimitar.gemspec` metadata for RubyGems.

# 1.0.0 (2020-03-24)

* Initial public release.
