# frozen_string_literal: true

require_relative 'lib/philiprehberger/typed_hash/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-typed_hash'
  spec.version       = Philiprehberger::TypedHash::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Hash with per-key type declarations, coercion, and validation'
  spec.description   = 'Define typed hash schemas with per-key type declarations, optional coercion functions, ' \
                       'default values, strict mode for unknown keys, and validation error collection.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-typed-hash'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
