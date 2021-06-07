# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocooned/version'

Gem::Specification.new do |spec|
  spec.name         = 'cocooned'
  spec.version      = Cocooned::VERSION
  spec.licenses     = ['Apache-2.0']
  spec.authors      = ['Gaël-Ian Havard', 'Nathan Van der Auwera']
  spec.email        = ['gael-ian@notus.sh', 'nathan@dixis.com']

  spec.summary      = 'Unobtrusive Rails nested forms handling, with or without jQuery.'
  spec.description  = 'Easier nested form. Supports standard Rails forms, Formtastic and SimpleForm.'
  spec.homepage     = 'http://github.com/notus-sh/cocooned'

  raise 'RubyGems 2.0 or newer is required.' unless spec.respond_to?(:metadata)

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.require_paths = ['lib']
  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(config|gemfiles|npm|spec)/}) ||
      %w[.gitignore .rspec .travis.yml].include?(f) ||
      %w[Gemfile Gemfile.lock package.json yarn.lock].include?(f)
  end
  spec.required_ruby_version = '>= 2.5'

  spec.add_dependency 'rails', '>= 5.0', '<= 7.0'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'jasmine', '~> 3.2'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.10.0'
  spec.add_development_dependency 'rspec-rails', '~> 4.0.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rails'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
end
