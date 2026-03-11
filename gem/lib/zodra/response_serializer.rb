# frozen_string_literal: true

module Zodra
  module ResponseSerializer
    def self.call(object, definition, key_format: Zodra.configuration.key_format, type_resolver: TypeRegistry.global)
      result = {}

      definition.attributes.each do |attr_name, attribute|
        value = extract_value(object, attr_name)
        serialized_key = transform_key(attr_name, key_format)

        if attribute.reference?
          referenced = type_resolver.find!(attribute.reference_name)
          result[serialized_key] = value.nil? ? nil : call(value, referenced, key_format:, type_resolver:)
        elsif attribute.array? && attribute.of
          referenced = type_resolver.find(attribute.of)
          result[serialized_key] = serialize_array(value, referenced, key_format:, type_resolver:)
        else
          result[serialized_key] = value
        end
      end

      result
    end

    def self.extract_value(object, attr_name)
      if object.respond_to?(attr_name)
        object.public_send(attr_name)
      elsif object.respond_to?(:key?)
        object.key?(attr_name) ? object[attr_name] : object[attr_name.to_s]
      elsif object.respond_to?(:[])
        object[attr_name]
      end
    end

    def self.serialize_array(values, element_definition, key_format:, type_resolver:)
      return [] if values.nil?

      if element_definition
        values.map { |element| call(element, element_definition, key_format:, type_resolver:) }
      else
        Array(values)
      end
    end

    def self.transform_key(key, key_format)
      key_string = key.to_s

      case key_format
      when :camel then camel_case(key_string)
      when :keep then key_string
      else key_string
      end
    end

    def self.camel_case(string)
      parts = string.split('_')
      parts.first + parts[1..].map(&:capitalize).join
    end

    private_class_method :extract_value, :serialize_array, :transform_key, :camel_case
  end
end
