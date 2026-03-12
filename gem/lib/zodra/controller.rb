# frozen_string_literal: true

require 'active_support/concern'

module Zodra
  module Controller
    extend ActiveSupport::Concern

    RAILS_INTERNAL_KEYS = %w[controller action format].freeze

    included do
      wrap_parameters false

      rescue_from Zodra::ParamsError do |error|
        key_format = Zodra.configuration.key_format
        render json: { errors: ErrorTransformer.transform_keys(error.errors, key_format:) }, status: :unprocessable_entity
      end
    end

    class_methods do
      def zodra_contract(name)
        @zodra_contract_name = name.to_sym
      end

      def zodra_contract_name
        @zodra_contract_name
      end

      def zodra_rescue(action_name, exception_class, as:)
        @zodra_rescue_mappings ||= []
        @zodra_rescue_mappings << { action_name: action_name.to_sym, exception_class:, code: as.to_sym }

        rescue_from exception_class do |exception|
          handle_zodra_business_error(exception)
        end
      end

      def zodra_rescue_mappings
        @zodra_rescue_mappings || []
      end
    end

    private

    def zodra_params
      @zodra_params ||= begin
        raw = request.parameters.except(*RAILS_INTERNAL_KEYS)
        raw = normalize_param_keys(raw)
        result = ParamsParser.call(raw, schema: zodra_action.params)
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
      normalized = ErrorTransformer.normalize(errors)
      ErrorTransformer.validate_keys!(normalized, valid_keys: valid_error_keys_for_action, action_name:)
      key_format = Zodra.configuration.key_format
      render json: { errors: ErrorTransformer.transform_keys(normalized, key_format:) }, status:
    end

    def zodra_action
      @zodra_action ||= zodra_contract.find_action(action_name) ||
                        raise(Zodra::Error,
                              "Action :#{action_name} not found in contract :#{self.class.zodra_contract_name}")
    end

    def zodra_contract
      @zodra_contract ||= ContractRegistry.global.find!(self.class.zodra_contract_name)
    end

    def serialize_response(object, schema)
      key_format = Zodra.configuration.key_format
      ResponseSerializer.call(object, schema, key_format:, type_resolver: zodra_contract)
    end

    def handle_zodra_business_error(exception)
      mapping = self.class.zodra_rescue_mappings.find do |m|
        m[:action_name] == action_name.to_sym && exception.is_a?(m[:exception_class])
      end

      raise exception unless mapping

      error_definition = zodra_action.find_error(mapping[:code])
      status = error_definition ? error_definition[:status] : :internal_server_error

      render json: { error: { code: mapping[:code].to_s, message: exception.message } }, status:
    end

    def valid_error_keys_for_action
      return @valid_error_keys_for_action if defined?(@valid_error_keys_for_action)

      @valid_error_keys_for_action = if zodra_action.error_keys_definition
                                       zodra_action.error_keys_definition
                                     else
                                       param_keys = zodra_action.params.attributes.keys
                                       param_keys.empty? ? nil : param_keys + [:base]
                                     end
    end

    def normalize_param_keys(value)
      return value if Zodra.configuration.key_format == :keep

      case value
      when Hash
        value.each_with_object({}) do |(key, val), result|
          result[key.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase] = normalize_param_keys(val)
        end
      when Array
        value.map { |item| normalize_param_keys(item) }
      else
        value
      end
    end
  end
end
