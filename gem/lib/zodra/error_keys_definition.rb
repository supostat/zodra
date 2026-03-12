# frozen_string_literal: true

module Zodra
  class ErrorKeysDefinition
    attr_reader :keys

    def initialize
      @keys = {}
    end

    def add_key(name, children: nil)
      sym = name.to_sym
      @keys[sym] = children
    end

    def add_keys_from_params(params_definition, except: [])
      excluded = Array(except).map(&:to_sym)

      params_definition.attributes.each do |attr_name, attribute|
        next if excluded.include?(attr_name)

        if attribute.array? && nested_definition?(attribute)
          child_def = resolve_nested(attribute)
          children = extract_keys_from_definition(child_def) if child_def
          @keys[attr_name] = children
        else
          @keys[attr_name] = nil
        end
      end
    end

    def children_for(key)
      @keys[key.to_sym]
    end

    def flat_keys
      @keys.keys
    end

    def empty?
      @keys.empty?
    end

    private

    def nested_definition?(attribute)
      attribute.reference_name || attribute.of
    end

    def resolve_nested(attribute)
      ref = attribute.reference_name || attribute.of
      return nil unless ref

      TypeRegistry.global.find(ref)
    end

    def extract_keys_from_definition(definition)
      result = {}
      definition.attributes.each do |attr_name, attribute|
        if attribute.array? && nested_definition?(attribute)
          child_def = resolve_nested(attribute)
          result[attr_name] = child_def ? extract_keys_from_definition(child_def) : nil
        else
          result[attr_name] = nil
        end
      end
      result
    end
  end
end
