# frozen_string_literal: true

require "active_support/concern"

module Zodra
  module Controller
    extend ActiveSupport::Concern

    included do
      rescue_from Zodra::ParamsError do |error|
        render json: { errors: transform_error_keys(error.errors) }, status: :unprocessable_entity
      end
    end

    class_methods do
      def zodra_contract(name)
        @zodra_contract_name = name.to_sym
      end

      def zodra_contract_name
        @zodra_contract_name
      end
    end

    private

    def zodra_params
      @zodra_params ||= begin
        result = ParamsParser.call(request.parameters, schema: zodra_action.params)
        raise ParamsError, result.errors unless result.valid?

        result.params
      end
    end

    def zodra_respond(object, status: :ok)
      schema = zodra_action.response_schema
      serialized = serialize_response(object, schema)
      render json: { data: serialized }, status:
    end

    def zodra_respond_collection(objects, status: :ok, meta: nil)
      schema = zodra_action.response_schema
      serialized = objects.map { |object| serialize_response(object, schema) }

      response_body = { data: serialized }
      response_body[:meta] = meta if meta
      render json: response_body, status:
    end

    def zodra_errors(errors, status: :unprocessable_entity)
      normalized = normalize_errors(errors)
      render json: { errors: transform_error_keys(normalized) }, status:
    end

    def zodra_action
      @zodra_action ||= zodra_contract.find_action(action_name) ||
        raise(Zodra::Error, "Action :#{action_name} not found in contract :#{self.class.zodra_contract_name}")
    end

    def zodra_contract
      @zodra_contract ||= ContractRegistry.global.find!(self.class.zodra_contract_name)
    end

    def serialize_response(object, schema)
      key_format = Zodra.configuration.key_format
      ResponseSerializer.call(object, schema, key_format:, type_resolver: zodra_contract)
    end

    def normalize_errors(errors)
      if errors.respond_to?(:to_hash)
        errors.to_hash
      elsif errors.respond_to?(:messages)
        errors.messages
      else
        errors
      end
    end

    def transform_error_keys(errors)
      key_format = Zodra.configuration.key_format
      return errors if key_format == :keep

      errors.transform_keys { |key| ResponseSerializer.send(:transform_key, key, key_format) }
    end
  end
end
