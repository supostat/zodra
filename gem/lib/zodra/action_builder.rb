# frozen_string_literal: true

module Zodra
  class ActionBuilder
    def initialize(action)
      @action = action
    end

    def params(&block)
      TypeBuilder.new(@action.params).instance_eval(&block)
    end

    def response(type_name = nil, collection: false, &block)
      @action.collection! if collection

      if block
        TypeBuilder.new(@action.response_definition).instance_eval(&block)
      elsif type_name
        @action.response_type = type_name.to_sym
      end
    end

    def error(code, status:)
      @action.add_error(code, status:)
    end
  end
end
