# frozen_string_literal: true

module Zodra
  module ParamsParser
    class Result
      attr_reader :params, :errors

      def initialize(params:, errors:)
        @params = params.freeze
        @errors = errors.freeze
      end

      def valid?
        errors.empty?
      end

      def invalid?
        !valid?
      end
    end

    def self.call(raw_params, schema:, strict: Zodra.configuration.strict_params)
      errors = {}
      errors.merge!(check_unknown_keys(raw_params, schema)) if strict
      filtered = filter(raw_params, schema)
      coerced = coerce(filtered, schema)
      errors.merge!(ParamsValidator.call(coerced, schema:))

      if errors.empty?
        apply_defaults(coerced, schema)
        Result.new(params: coerced, errors: {})
      else
        Result.new(params: {}, errors:)
      end
    end

    def self.check_unknown_keys(raw_params, schema)
      known_keys = schema.attributes.keys
      unknown_keys = raw_params.keys.map(&:to_sym) - known_keys
      errors = {}

      unknown_keys.each do |key|
        errors[key] = ['is not allowed']
      end

      errors
    end

    def self.filter(raw_params, schema)
      known_keys = schema.attributes.keys
      result = {}

      raw_params.each do |key, value|
        sym_key = key.to_sym
        result[sym_key] = value if known_keys.include?(sym_key)
      end

      result
    end

    def self.coerce(params, schema)
      coerced = {}

      schema.attributes.each do |attr_name, attribute|
        next unless params.key?(attr_name)

        value = params[attr_name]

        coerced[attr_name] = if value.nil? && attribute.nullable?
                               nil
                             else
                               ParamsCoercer.call(value, attribute.type, of: attribute.of)
                             end
      end

      coerced
    end

    def self.apply_defaults(params, schema)
      schema.attributes.each do |attr_name, attribute|
        next if params.key?(attr_name)
        next if attribute.default.nil?

        params[attr_name] = attribute.default
      end
    end

    private_class_method :check_unknown_keys, :filter, :coerce, :apply_defaults
  end
end
