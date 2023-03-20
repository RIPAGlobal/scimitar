# 2.4.2 (2023-03-21)

* Fix shortcoming in `Content-Type` header handling via [#51](https://github.com/RIPAGlobal/scimitar/pull/51). Thanks to `@Flixt` for the contribution.

# 2.4.1 (2023-03-02)

* Address https://github.com/RIPAGlobal/scimitar/issues/48 by adapting https://github.com/RIPAGlobal/scimitar/issues/49, so that extension schemas work properly. Missing documentation in `README.md` addressed. Thanks to `bettysteger` and `@MorrisFreeman` for the contribution.

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
