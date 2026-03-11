# frozen_string_literal: true

require_relative 'lib/zodra/version'

Gem::Specification.new do |spec|
  spec.name = 'zodra'
  spec.version = Zodra::VERSION
  spec.authors = ['Zodra Contributors']
  spec.summary = 'End-to-end type system for Rails: DSL → TypeScript + Zod'
  spec.description = 'Define types once in Ruby DSL, generate TypeScript interfaces ' \
                     'and Zod schemas for runtime validation on both ends.'
  spec.homepage = 'https://github.com/supostat/zodra'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.2'

  spec.files = Dir['lib/**/*', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'railties', '>= 7.1'
  spec.add_dependency 'zeitwerk', '>= 2.6'

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/gem/CHANGELOG.md"
end
