# frozen_string_literal: true

module Zodra
  module ErrorTransformer
    module_function

    def normalize(errors)
      if errors.respond_to?(:to_hash)
        errors.to_hash
      elsif errors.respond_to?(:messages)
        errors.messages
      else
        errors
      end
    end

    def transform_keys(errors, key_format:)
      return errors if key_format == :keep

      errors.each_with_object({}) do |(key, value), result|
        new_key = ResponseSerializer.send(:transform_key, key, key_format)
        result[new_key] = transform_value(value, key_format:)
      end
    end

    def validate_keys!(errors, valid_keys:, action_name:)
      return unless valid_keys

      if valid_keys.is_a?(ErrorKeysDefinition)
        validate_keys_recursive!(errors, valid_keys.keys, path: [], action_name:)
      else
        validate_flat_keys!(errors, valid_keys, action_name:)
      end
    end

    def transform_value(value, key_format:)
      case value
      when Hash
        transform_keys(value, key_format:)
      when Array
        value.map { |element| element.is_a?(Hash) ? transform_keys(element, key_format:) : element }
      else
        value
      end
    end

    def validate_flat_keys!(errors, valid_keys, action_name:)
      unknown_keys = errors.keys.map(&:to_sym) - valid_keys
      return if unknown_keys.empty?

      report_unknown_keys!(unknown_keys, valid_keys, path: [], action_name:)
    end

    def validate_keys_recursive!(errors, valid_keys_hash, path:, action_name:)
      unknown_keys = errors.keys.map(&:to_sym) - valid_keys_hash.keys
      report_unknown_keys!(unknown_keys, valid_keys_hash.keys, path:, action_name:) unless unknown_keys.empty?

      valid_keys_hash.each do |key, children|
        next unless children
        next unless errors.key?(key) || errors.key?(key.to_s)

        value = errors[key] || errors[key.to_s]
        next unless value.is_a?(Array)

        value.each_with_index do |element, index|
          next unless element.is_a?(Hash)

          validate_keys_recursive!(element, children, path: path + ["#{key}[#{index}]"], action_name:)
        end
      end
    end

    def report_unknown_keys!(unknown_keys, valid_keys, path:, action_name:)
      location = path.empty? ? '' : " in #{path.join('.')}"
      message = "Unknown error keys #{unknown_keys.inspect}#{location} for action :#{action_name}. " \
                "Valid keys: #{valid_keys.inspect}"

      raise Zodra::Error, message if defined?(Rails) && !Rails.env.production?

      Zodra.logger&.warn("[Zodra] #{message}")
    end
  end
end
