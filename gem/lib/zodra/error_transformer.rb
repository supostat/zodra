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

      errors.transform_keys { |key| ResponseSerializer.send(:transform_key, key, key_format) }
    end

    def validate_keys!(errors, valid_keys:, action_name:)
      return unless valid_keys

      unknown_keys = errors.keys.map(&:to_sym) - valid_keys
      return if unknown_keys.empty?

      message = "Unknown error keys #{unknown_keys.inspect} for action :#{action_name}. " \
                "Valid keys: #{valid_keys.inspect}"

      raise Zodra::Error, message if defined?(Rails) && !Rails.env.production?

      Zodra.logger&.warn("[Zodra] #{message}")
    end
  end
end
