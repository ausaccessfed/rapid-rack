# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rapid_rack/version'

Gem::Specification.new do |spec|
  spec.name          = 'rapid_rack'
  spec.version       = RapidRack::VERSION
  spec.authors       = ['Shaun Mangelsdorf']
  spec.email         = ['s.mangelsdorf@gmail.com']
  spec.summary       = 'Rack middleware for AAF Rapid Connect authentication.'
  spec.homepage      = 'https://github.com/ausaccessfed/rapid_rack'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_dependency 'json-jwt'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'capybara'
  spec.add_development_dependency 'simplecov'

  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-bundler'
end
