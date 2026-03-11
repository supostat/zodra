# frozen_string_literal: true

module Zodra
  module ParamsValidator
    STRING_TYPES = %i[string uuid binary].freeze
    NUMERIC_TYPES = %i[integer decimal number].freeze

    def self.call(params, schema:)
      errors = {}

      schema.attributes.each do |attr_name, attribute|
        validate_attribute(params, attr_name, attribute, errors)
      end

      errors
    end

    def self.validate_attribute(params, attr_name, attribute, errors)
      present = params.key?(attr_name)
      value = params[attr_name]

      if !present || (value.nil? && !attribute.nullable?)
        return if (attribute.optional? || !attribute.default.nil?) && !present

        errors[attr_name] = ["is required"]
        return
      end

      return if value.nil? && attribute.nullable?

      if value == :coercion_error
        errors[attr_name] = ["is not a valid #{attribute.type}"]
        return
      end

      validate_constraints(value, attribute, errors)
    end

    def self.validate_constraints(value, attribute, errors)
      field_errors = []
      resolved_type = resolve_base_type(attribute.type)

      if attribute.enum
        allowed = attribute.enum.map(&:to_s)
        field_errors << "is not included in the list" unless allowed.include?(value.to_s)
      end

      if attribute.min
        if STRING_TYPES.include?(resolved_type)
          field_errors << "is too short (minimum is #{attribute.min} characters)" if value.to_s.length < attribute.min
        elsif NUMERIC_TYPES.include?(resolved_type)
          field_errors << "must be greater than or equal to #{attribute.min}" if value < attribute.min
        end
      end

      if attribute.max
        if STRING_TYPES.include?(resolved_type)
          field_errors << "is too long (maximum is #{attribute.max} characters)" if value.to_s.length > attribute.max
        elsif NUMERIC_TYPES.include?(resolved_type)
          field_errors << "must be less than or equal to #{attribute.max}" if value > attribute.max
        end
      end

      errors[attribute.name] = field_errors if field_errors.any?
    end

    def self.resolve_base_type(type)
      scalar = ScalarRegistry.global.find(type)
      scalar ? scalar.base : type
    end

    private_class_method :validate_attribute, :validate_constraints, :resolve_base_type
  end
end
