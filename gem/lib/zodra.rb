# frozen_string_literal: true

require "zeitwerk"

module Zodra
  class Error < StandardError; end
  class DuplicateTypeError < Error; end
  class ConfigurationError < Error; end

  class << self
    def type(name, &block)
      definition = TypeRegistry.global.register(name, kind: :object)
      TypeBuilder.new(definition).instance_eval(&block) if block
      definition
    end

    def enum(name, values:)
      TypeRegistry.global.register(name, kind: :enum, values:)
    end

    def union(name, discriminator:, &block)
      definition = TypeRegistry.global.register(name, kind: :union, discriminator:)
      UnionBuilder.new(definition).instance_eval(&block) if block
      definition
    end

    private

    def setup_autoload
      @loader = Zeitwerk::Loader.for_gem.tap do |loader|
        loader.inflector.inflect("dsl" => "DSL")
        loader.setup
      end
    end
  end

  setup_autoload
end
