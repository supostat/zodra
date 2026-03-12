# frozen_string_literal: true

require 'zeitwerk'
require 'active_support/core_ext/string/inflections'

module Zodra
  class Error < StandardError; end
  class DuplicateTypeError < Error; end
  class ConfigurationError < Error; end

  class ParamsError < Error
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super('Params validation failed')
    end
  end

  class << self
    def logger
      @logger || (defined?(Rails) ? Rails.logger : nil)
    end

    attr_writer :logger

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def type(name, from: nil, pick: nil, omit: nil, partial: false, &block)
      raise DuplicateTypeError, "Type :#{name} is already registered" if TypeRegistry.global.exists?(name)

      definition = Definition.new(name:, kind: :object)

      if from
        source = TypeRegistry.global.find!(from)
        TypeDeriver.new(source, pick:, omit:, partial:).apply(definition)
      end

      TypeBuilder.new(definition).instance_eval(&block) if block
      TypeRegistry.global.store(name, definition)
      definition
    end

    def enum(name, values:)
      TypeRegistry.global.register(name, kind: :enum, values:)
    end

    def union(name, discriminator:, &block)
      raise DuplicateTypeError, "Type :#{name} is already registered" if TypeRegistry.global.exists?(name)

      definition = Definition.new(name:, kind: :union, discriminator:)
      UnionBuilder.new(definition).instance_eval(&block) if block
      TypeRegistry.global.store(name, definition)
      definition
    end

    def contract(name, &block)
      contract = ContractRegistry.global.register(name)
      ContractBuilder.new(contract).instance_eval(&block) if block
      contract
    end

    def api(base_path, &block)
      api_definition = ApiRegistry.global.register(base_path)
      ApiBuilder.new(api_definition).instance_eval(&block) if block
      api_definition
    end

    def scalar(name, base:, &coercer)
      ScalarRegistry.global.register(name, base:, coercer:)
    end

    def load_definitions!
      return unless defined?(Rails)

      ScalarRegistry.global.clear!
      TypeRegistry.global.clear!
      ContractRegistry.global.clear!
      ApiRegistry.global.clear!

      load_definition_dir(Rails.root.join('app/types'))
      load_definition_dir(Rails.root.join('app/contracts'))
      load_definition_dir(Rails.root.join('config/apis'))

      resolve_routes!
    end

    def resolve_routes!
      ApiRegistry.global.each do |api_definition|
        api_definition.resources.each do |resource|
          resolve_resource_routes(resource, api_definition.base_path)
        end
      end
    end

    private

    def load_definition_dir(path)
      files = Dir[path.join('**/*.rb')]
      failed = []

      files.each do |file|
        load(file)
      rescue NoMethodError => e
        logger&.debug { "Deferring load of #{file}: #{e.message}" }
        failed << file
      end

      failed.each { |file| load(file) }
    end

    def resolve_resource_routes(resource, base_path, parent_param: nil)
      segment = resource.name.to_s
      resource_path = parent_param ? "#{base_path}/#{parent_param}/#{segment}" : "#{base_path}/#{segment}"

      contract = ContractRegistry.global.find(resource.contract_name)

      if contract
        resource.crud_actions.each do |action_name|
          action = contract.find_action(action_name)
          next unless action

          crud = Resource::CRUD_ACTIONS[action_name]
          action.http_method = crud[:http_method]
          action.path = crud[:member] && !resource.singular? ? "#{resource_path}/:id" : resource_path
        end

        resource.custom_actions.each do |custom|
          action = contract.find_action(custom[:name])
          next unless action

          action.http_method = custom[:http_method]
          action.path = custom[:member] && !resource.singular? ? "#{resource_path}/:id/#{custom[:name]}" : "#{resource_path}/#{custom[:name]}"
        end
      end

      resource.children.each do |child|
        child_parent_param = resource.singular? ? nil : ":#{resource.name.to_s.singularize}_id"
        resolve_resource_routes(child, resource_path, parent_param: child_parent_param)
      end
    end

    def setup_autoload
      @loader = Zeitwerk::Loader.for_gem.tap do |loader|
        loader.inflector.inflect('dsl' => 'DSL')
        loader.ignore("#{__dir__}/generators")
        loader.ignore("#{__dir__}/ruby_lsp")
        loader.ignore("#{__dir__}/zodra/tasks")
        loader.ignore("#{__dir__}/zodra/railtie.rb")
        loader.ignore("#{__dir__}/zodra/swagger.rb")
        loader.ignore("#{__dir__}/zodra/swagger")
        loader.setup
      end
    end
  end

  setup_autoload

  if defined?(Rails::Railtie)
    require 'zodra/railtie'
    require 'zodra/swagger'
  end
end
