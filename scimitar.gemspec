$:.push File.expand_path('../lib', __FILE__)
require 'scimitar/version'

Gem::Specification.new do |s|
  s.name        = 'scimitar'
  s.version     = Scimitar::VERSION
  s.date        = Scimitar::DATE
  s.summary     = 'SCIM v2 for Rails'
  s.description = 'SCIM v2 support for Users and Groups in Ruby On Rails'
  s.authors     = ['RIP Global', 'Andrew David Hodgkinson']
  s.email       = ['andrew@ripglobal.com']
  s.license     = 'MIT'

  s.files       = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files  = Dir.glob('spec/**/*.rb')
  s.homepage    = 'https://ripglobal.com/'

  s.required_ruby_version = '>= 2.7.2'

  s.add_dependency 'rails',    '>= 6.0'
  s.add_dependency 'nokogiri', '~> 1.11'

  s.add_development_dependency 'rake',           '~> 13.0'
  s.add_development_dependency 'simplecov-rcov', '~>  0.2'
  s.add_development_dependency 'rdoc',           '~>  6.3'
  s.add_development_dependency 'rspec-rails',    '~>  4.0'
  s.add_development_dependency 'byebug',         '~> 11.1'
  s.add_development_dependency 'doggo',          '~>  1.1'
end
