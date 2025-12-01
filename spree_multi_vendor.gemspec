# encoding: UTF-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_multi_vendor/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_multi_vendor'
  s.version     = SpreeMultiVendor::VERSION
  s.summary     = "Spree Commerce Multi vendor Extension"
  s.required_ruby_version = '>= 3.0'

  s.authors   = ['Vendo Connect Inc.', 'Vendo Sp. z o.o.']
  s.email     = 'hello@spreecommerce.org'
  s.homepage  = 'https://github.com/spree/spree_multi_vendor'

  s.files        = Dir["{app,config,db,lib,vendor}/**/*", "LICENSE.md", "Rakefile", "README.md"].reject { |f| f.match(/^spec/) && !f.match(/^spec\/fixtures/) }
  s.require_path = 'lib'
  s.requirements << 'none'

  spree_version = '>= 5.2.0'
  s.add_dependency 'spree', spree_version
  s.add_dependency 'spree_admin', spree_version

  s.add_dependency 'spree_extension'

  s.add_development_dependency 'email_spec'
  s.add_development_dependency 'spree_dev_tools'
  s.add_development_dependency 'timecop'
end
