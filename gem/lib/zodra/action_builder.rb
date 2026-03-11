# frozen_string_literal: true

module Zodra
  class ActionBuilder
    def initialize(action)
      @action = action
    end

    HTTP_METHODS = %i[get post put patch delete].freeze

    HTTP_METHODS.each do |verb|
      define_method(verb) do |action_path|
        @action.http_method = verb
        @action.path = action_path
      end
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
  end
end
