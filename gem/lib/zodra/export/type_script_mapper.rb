# frozen_string_literal: true

module Zodra
  module Export
    class TypeScriptMapper
      include NamingConventions

      PRIMITIVE_MAP = {
        string: 'string',
        integer: 'number',
        decimal: 'number',
        number: 'number',
        boolean: 'boolean',
        datetime: 'string',
        date: 'string',
        uuid: 'string',
        binary: 'string'
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

      def map_definitions(definitions, cycles: Set.new)
        definitions.map { |definition| map_definition(definition) }.join("\n\n")
      end

      def map_contract(contract, base_path: nil)
        params_output = map_contract_params(contract)
        responses_output = map_contract_responses(contract)
        descriptor_output = map_contract_descriptor(contract, base_path:)
        [params_output, responses_output, descriptor_output].compact.reject(&:empty?).join("\n\n")
      end

      def map_contracts(contracts, base_path: nil)
        contracts.map { |contract| map_contract(contract, base_path:) }.join("\n\n")
      end

      private

      def map_object(definition)
        properties = definition.attributes.values.map { |attr| map_property(attr) }
        body = "export interface #{pascal_case(definition.name)} {\n#{properties.join("\n")}\n}"
        prepend_jsdoc(body, definition.description)
      end

      def map_enum(definition)
        values = definition.values.map { |value| "'#{value}'" }.join(' | ')
        body = "export type #{pascal_case(definition.name)} = #{values};"
        prepend_jsdoc(body, definition.description)
      end

      def map_union(definition)
        variants = definition.variants.map { |variant| map_variant(variant, definition.discriminator) }
        body = "export type #{pascal_case(definition.name)} =\n#{variants.join("\n")};"
        prepend_jsdoc(body, definition.description)
      end

      def map_variant(variant, discriminator)
        discriminator_key = transform_key(discriminator)
        properties = variant.attributes.values.map do |attr|
          "#{attr.as || transform_key(attr.name)}: #{map_type(attr)}"
        end
        all_properties = ["#{discriminator_key}: '#{variant.tag}'"] + properties
        "  | { #{all_properties.join('; ')} }"
      end

      def map_property(attribute)
        key = attribute.as || transform_key(attribute.name)
        optional_marker = attribute.optional? ? '?' : ''
        type_string = map_type(attribute)
        type_string = [type_string, 'null'].sort.join(' | ') if attribute.nullable?
        line = "  #{key}#{optional_marker}: #{type_string};"
        jsdoc = property_jsdoc(attribute)
        jsdoc ? "#{jsdoc}\n#{line}" : line
      end

      def map_type(attribute)
        if attribute.enum
          attribute.enum.map { |v| "'#{v}'" }.join(' | ')
        elsif attribute.enum_ref?
          pascal_case(attribute.enum_type_name)
        elsif attribute.reference?
          pascal_case(attribute.reference_name)
        elsif attribute.array?
          inner = resolve_array_element_type(attribute.of)
          "#{inner}[]"
        else
          resolve_primitive_type(attribute.type)
        end
      end

      def transform_key(key)
        key_string = key.to_s
        case @key_format
        when :camel then camel_case(key_string)
        when :pascal then pascal_case(key_string)
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

      def map_contract_responses(contract)
        parts = contract.actions.values.filter_map do |action|
          next unless action.inline_response?

          response_name = :"#{action.name}_#{contract.name}_response"
          renamed = Definition.new(name: response_name, kind: :object)
          action.response_definition.attributes.each { |key, attr| renamed.attributes[key] = attr }
          map_object(renamed)
        end

        parts.join("\n\n")
      end

      def map_contract_descriptor(contract, base_path: nil)
        name = pascal_case(contract.name)
        return "export interface #{name}Contract {}" if contract.actions.empty?

        entries = contract.actions.values.map do |action|
          path = strip_base_path(action.path, base_path)
          params_type = "#{pascal_case(action.name)}#{name}Params"
          parts = ["method: '#{action.http_method.to_s.upcase}'", "path: '#{path}'", "params: #{params_type}"]
          if action.response_type
            parts << "response: #{pascal_case(action.response_type)}"
          elsif action.inline_response?
            parts << "response: #{pascal_case(action.name)}#{name}Response"
          end
          parts << 'collection: true' if action.collection?
          "  #{action.name}: { #{parts.join('; ')} };"
        end

        "export interface #{name}Contract {\n#{entries.join("\n")}\n}"
      end

      def prepend_jsdoc(body, description)
        return body unless description

        "/** #{description} */\n#{body}"
      end

      def property_jsdoc(attribute)
        parts = []
        parts << attribute.description if attribute.description
        parts << '@deprecated' if attribute.deprecated?
        return nil if parts.empty?

        "  /** #{parts.join(' - ')} */"
      end

      def resolve_array_element_type(element_type)
        PRIMITIVE_MAP.fetch(element_type) do
          scalar = ScalarRegistry.global.find(element_type)
          if scalar
            PRIMITIVE_MAP.fetch(scalar.base, pascal_case(element_type))
          else
            pascal_case(element_type)
          end
        end
      end

      def resolve_primitive_type(type)
        PRIMITIVE_MAP.fetch(type) do
          scalar = ScalarRegistry.global.find(type)
          scalar ? PRIMITIVE_MAP.fetch(scalar.base, 'unknown') : 'unknown'
        end
      end
    end
  end
end
