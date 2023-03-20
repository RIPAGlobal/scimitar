# 1.5.1 (2023-03-20)

* Back-ports features from v2.3.1 (addressing https://github.com/RIPAGlobal/scimitar/issues/48 by incorporating https://github.com/RIPAGlobal/scimitar/issues/49 into https://github.com/RIPAGlobal/scimitar/issues/50), for Rails 6 users.

# 1.5.0 (2023-01-27)

* Back-ports features from v2.3.0 (addressing https://github.com/RIPAGlobal/scimitar/issues/43) for Rails 6 users.

# 1.4.0 (2023-01-26)

* Back-ports fixes from v2.2.0 (Ruby v3.2.0 local development support and move to GitHub actions, mostly for this repo's sake) and v2.3.0 (fixes https://github.com/RIPAGlobal/scimitar/issues/35), for Rails 6 users.

# 1.3.3 (2023-01-10)

* Back-ports fixes from v2.1.3 for Rails 6 users.

# 1.3.2 (2023-01-10)

* Back-ports fixes from v2.1.2 for Rails 6 users.

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
