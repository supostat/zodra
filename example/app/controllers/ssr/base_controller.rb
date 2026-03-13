# frozen_string_literal: true

module Ssr
  class BaseController < ActionController::Base
    layout "ssr"

    private

    def zodra_serialize(object, type_name)
      definition = Zodra::TypeRegistry.global.find!(type_name)
      Zodra::ResponseSerializer.call(object, definition, key_format: :camel)
    end

    def zodra_serialize_many(objects, type_name)
      definition = Zodra::TypeRegistry.global.find!(type_name)
      objects.map { |obj| Zodra::ResponseSerializer.call(obj, definition, key_format: :camel) }
    end

    def zodra_serialize_inline(object, contract_name, action_name)
      contract = Zodra::ContractRegistry.global.find!(contract_name)
      action = contract.find_action(action_name)
      Zodra::ResponseSerializer.call(object, action.response_definition, key_format: :camel)
    end

    def camelize_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(key, val), result|
          result[key.to_s.camelize(:lower)] = camelize_keys(val)
        end
      when Array
        obj.map { |item| camelize_keys(item) }
      else
        obj
      end
    end
  end
end
