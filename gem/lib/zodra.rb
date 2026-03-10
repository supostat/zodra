# frozen_string_literal: true

require "zeitwerk"

module Zodra
  class Error < StandardError; end
  class DuplicateTypeError < Error; end
  class ConfigurationError < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

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

    def contract(name, &block)
      contract = ContractRegistry.global.register(name)
      ContractBuilder.new(contract).instance_eval(&block) if block
      contract
    end

    private

    def setup_autoload
      @loader = Zeitwerk::Loader.for_gem.tap do |loader|
        loader.inflector.inflect("dsl" => "DSL")
        loader.ignore("#{__dir__}/generators")
        loader.ignore("#{__dir__}/zodra/tasks")
        loader.ignore("#{__dir__}/zodra/railtie.rb")
        loader.setup
      end
    end
  end

  setup_autoload

  require "zodra/railtie" if defined?(Rails::Railtie)
end
