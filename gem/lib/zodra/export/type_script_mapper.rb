# frozen_string_literal: true

module Zodra
  module Export
    class TypeScriptMapper
      PRIMITIVE_MAP = {
        string: "string",
        integer: "number",
        decimal: "number",
        number: "number",
        boolean: "boolean",
        datetime: "string",
        date: "string",
        uuid: "string",
        binary: "string"
      }.freeze

      def initialize(key_format: :keep)
        @key_format = key_format
      end

      def map_definition(definition)
        case definition.kind
        when :object then map_object(definition)
        when :enum then map_enum(definition)
        when :union then map_union(definition)
        end
      end

      def map_definitions(definitions)
        definitions.map { |definition| map_definition(definition) }.join("\n\n")
      end

      def map_contract(contract)
        params_output = map_contract_params(contract)
        descriptor_output = map_contract_descriptor(contract)
        [params_output, descriptor_output].compact.reject(&:empty?).join("\n\n")
      end

      def map_contracts(contracts)
        contracts.map { |contract| map_contract(contract) }.join("\n\n")
      end

      private

      def map_object(definition)
        properties = definition.attributes.values.map { |attr| map_property(attr) }
        "export interface #{pascal_case(definition.name)} {\n#{properties.join("\n")}\n}"
      end

      def map_enum(definition)
        values = definition.values.map { |value| "'#{value}'" }.join(" | ")
        "export type #{pascal_case(definition.name)} = #{values};"
      end

      def map_union(definition)
        variants = definition.variants.map { |variant| map_variant(variant, definition.discriminator) }
        "export type #{pascal_case(definition.name)} =\n#{variants.join("\n")};"
      end

      def map_variant(variant, discriminator)
        discriminator_key = transform_key(discriminator)
        properties = variant.attributes.values.map do |attr|
          "#{transform_key(attr.name)}: #{map_type(attr)}"
        end
        all_properties = ["#{discriminator_key}: '#{variant.tag}'"] + properties
        "  | { #{all_properties.join('; ')} }"
      end

      def map_property(attribute)
        key = transform_key(attribute.name)
        optional_marker = attribute.optional? ? "?" : ""
        type_string = map_type(attribute)
        type_string = [type_string, "null"].sort.join(" | ") if attribute.nullable?
        "  #{key}#{optional_marker}: #{type_string};"
      end

      def map_type(attribute)
        if attribute.reference?
          pascal_case(attribute.reference_name)
        elsif attribute.array?
          "#{pascal_case(attribute.of)}[]"
        else
          resolve_primitive_type(attribute.type)
        end
      end

      def transform_key(key)
        key_string = key.to_s
        case @key_format
        when :camel then camel_case(key_string)
        when :pascal then pascal_case_string(key_string)
        else key_string
        end
      end

      def map_contract_params(contract)
        contract.actions.values.map do |action|
          params_name = :"#{action.name}_#{contract.name}_params"
          renamed = Definition.new(name: params_name, kind: :object)
          action.params.attributes.each { |key, attr| renamed.attributes[key] = attr }
          map_object(renamed)
        end.join("\n\n")
      end

      def map_contract_descriptor(contract)
        name = pascal_case(contract.name)
        return "export interface #{name}Contract {}" if contract.actions.empty?

        entries = contract.actions.values.map do |action|
          params_type = "#{pascal_case(action.name)}#{name}Params"
          parts = ["method: '#{action.http_method.to_s.upcase}'", "path: '#{action.path}'", "params: #{params_type}"]
          parts << "response: #{pascal_case(action.response_type)}" if action.response_type
          "  #{action.name}: { #{parts.join('; ')} };"
        end

        "export interface #{name}Contract {\n#{entries.join("\n")}\n}"
      end

      def resolve_primitive_type(type)
        PRIMITIVE_MAP.fetch(type) do
          scalar = ScalarRegistry.global.find(type)
          scalar ? PRIMITIVE_MAP.fetch(scalar.base, "unknown") : "unknown"
        end
      end

      def pascal_case(name)
        name.to_s.split("_").map(&:capitalize).join
      end

      def pascal_case_string(string)
        string.split("_").map(&:capitalize).join
      end

      def camel_case(string)
        parts = string.split("_")
        parts.first + parts[1..].map(&:capitalize).join
      end
    end
  end
end
