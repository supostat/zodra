# frozen_string_literal: true

module Zodra
  class Action
    attr_reader :name, :params, :contract, :response_definition, :errors

    attr_accessor :http_method, :path, :response_type, :error_keys_definition,
                  :params_source_type, :description, :deprecated_message

    def initialize(name:, contract: nil)
      @name = name
      @contract = contract
      @params = Definition.new(name: :"#{name}_params", kind: :object)
      @response_definition = Definition.new(name: :"#{name}_response", kind: :object)
      @response_type = nil
      @collection = false
      @errors = {}
      @error_keys_definition = nil
    end

    def add_error(code, status:)
      @errors[code.to_sym] = { code: code.to_sym, status: status }
    end

    def find_error(code)
      @errors[code.to_sym]
    end

    def deprecated?
      !@deprecated_message.nil?
    end

    def collection?
      @collection
    end

    def collection!
      @collection = true
    end

    def inline_response?
      response_type.nil? && response_definition.attributes.any?
    end

    def response_schema
      if response_type
        contract&.resolve_type(response_type) || TypeRegistry.global.find!(response_type)
      else
        response_definition
      end
    end
  end
end
