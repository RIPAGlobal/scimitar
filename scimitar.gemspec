$:.push File.expand_path('../lib', __FILE__)
require 'scimitar/version'

Gem::Specification.new do |s|
  s.name        = 'scimitar'
  s.version     = Scimitar::VERSION
  s.date        = Scimitar::DATE
  s.summary     = 'SCIM v2 for Rails'
  s.description = 'SCIM v2 support for Users and Groups in Ruby On Rails'
  s.authors     = ['RIPA Global', 'Andrew David Hodgkinson']
  s.email       = ['dev@ripaglobal.com']
  s.license     = 'MIT'

  s.files       = Dir['{app,config,db,lib}/**/*', 'LICENSE.txt', 'Rakefile', 'README.md']
  s.test_files  = Dir.glob('spec/**/*.rb')
  s.homepage    = 'https://www.ripaglobal.com/'

  s.metadata['homepage_uri'   ] = s.homepage
  s.metadata['source_code_uri'] = 'https://github.com/RIPAGlobal/scimitar/'
  s.metadata['bug_tracker_uri'] = 'https://github.com/RIPAGlobal/scimitar/issues/'
  s.metadata['changelog_uri'  ] = 'https://github.com/RIPAGlobal/scimitar/blob/main/CHANGELOG.md'

  s.required_ruby_version = '>= 2.7.0'

  s.add_dependency 'rails', '~> 8.0'

  s.add_development_dependency 'debug',          '~>  1.9'
  s.add_development_dependency 'rake',           '~> 13.2'
  s.add_development_dependency 'pg',             '~>  1.5'
  s.add_development_dependency 'simplecov-rcov', '~>  0.3'
  s.add_development_dependency 'rdoc',           '~>  6.7'
  s.add_development_dependency 'rspec-rails',    '~>  7.0'
  s.add_development_dependency 'doggo',          '~>  1.3'
end
