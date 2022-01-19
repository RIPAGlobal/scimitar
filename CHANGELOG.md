# 2.0.0 (2022-01-20)

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
