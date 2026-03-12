# frozen_string_literal: true

module Zodra
  class ActionBuilder
    def initialize(action)
      @action = action
    end

    def params(from: nil, pick: nil, omit: nil, partial: false, &block)
      if from
        source = resolve_type(from)
        TypeDeriver.new(source, pick:, omit:, partial:).apply(@action.params)
      end

      TypeBuilder.new(@action.params).instance_eval(&block) if block
    end

    def response(type_name = nil, collection: false, &block)
      @action.collection! if collection

      if block
        TypeBuilder.new(@action.response_definition).instance_eval(&block)
      elsif type_name
        @action.response_type = type_name.to_sym
      end
    end

    def errors(&)
      definition = ErrorKeysDefinition.new
      ErrorKeysBuilder.new(definition, params_definition: @action.params).instance_eval(&)
      @action.error_keys_definition = definition
    end

    def error(code, status:)
      @action.add_error(code, status:)
    end

    private

    def resolve_type(name)
      @action.contract&.resolve_type(name) || TypeRegistry.global.find!(name)
    end
  end
end
