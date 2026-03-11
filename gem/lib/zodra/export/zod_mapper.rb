# frozen_string_literal: true

module Zodra
  module Export
    class ZodMapper
      PRIMITIVE_MAP = {
        string: "z.string()",
        integer: "z.number().int()",
        decimal: "z.number()",
        number: "z.number()",
        boolean: "z.boolean()",
        datetime: "z.string().datetime()",
        date: "z.string().date()",
        uuid: "z.string().uuid()",
        binary: "z.string()"
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
        properties = definition.attributes.values.map { |attr| "  #{map_property(attr)}," }
        "export const #{pascal_case(definition.name)}Schema = z.object({\n#{properties.join("\n")}\n});"
      end

      def map_enum(definition)
        values = definition.values.map { |value| "'#{value}'" }.join(", ")
        "export const #{pascal_case(definition.name)}Schema = z.enum([#{values}]);"
      end

      def map_union(definition)
        discriminator_key = transform_key(definition.discriminator)
        variants = definition.variants.map { |variant| map_variant(variant, discriminator_key) }
        indent = "  "
        "export const #{pascal_case(definition.name)}Schema = z.discriminatedUnion('#{discriminator_key}', [\n" \
          "#{variants.map { |v| "#{indent}#{v}" }.join(",\n")},\n]);"
      end

      def map_variant(variant, discriminator_key)
        properties = variant.attributes.values.map { |attr| "#{transform_key(attr.name)}: #{map_zod_type(attr)}" }
        all_properties = ["#{discriminator_key}: z.literal('#{variant.tag}')"] + properties
        "z.object({ #{all_properties.join(', ')} })"
      end

      def map_property(attribute)
        key = transform_key(attribute.name)
        "#{key}: #{map_zod_type(attribute)}"
      end

      def map_zod_type(attribute)
        base = resolve_base_type(attribute)
        base = apply_constraints(base, attribute)
        base = apply_modifiers(base, attribute)
        base
      end

      def resolve_base_type(attribute)
        if attribute.reference?
          "#{pascal_case(attribute.reference_name)}Schema"
        elsif attribute.array?
          "z.array(#{pascal_case(attribute.of)}Schema)"
        else
          PRIMITIVE_MAP.fetch(attribute.type, "z.unknown()")
        end
      end

      def apply_constraints(base, attribute)
        base = "#{base}.min(#{attribute.min})" if attribute.min
        base = "#{base}.max(#{attribute.max})" if attribute.max
        base
      end

      def apply_modifiers(base, attribute)
        base = "#{base}.default(#{format_default(attribute.default)})" unless attribute.default.nil?
        base = "#{base}.nullable()" if attribute.nullable?
        base = "#{base}.optional()" if attribute.optional?
        base
      end

      def format_default(value)
        case value
        when String then "'#{value}'"
        when Symbol then "'#{value}'"
        else value
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

      def map_contract_descriptor(contract)
        name = pascal_case(contract.name)
        return "export const #{name}Contract = {} as const;" if contract.actions.empty?

        entries = contract.actions.values.map do |action|
          params_schema = "#{pascal_case(action.name)}#{name}ParamsSchema"
          parts = ["method: '#{action.http_method.to_s.upcase}' as const", "path: '#{action.path}' as const", "params: #{params_schema}"]
          parts << "response: #{pascal_case(action.response_type)}Schema" if action.response_type
          "  #{action.name}: { #{parts.join(', ')} }"
        end

        "export const #{name}Contract = {\n#{entries.join(",\n")},\n} as const;"
      end

      def pascal_case(name)
        name.to_s.split("_").map(&:capitalize).join
      end

      def camel_case(string)
        parts = string.split("_")
        parts.first + parts[1..].map(&:capitalize).join
      end
    end
  end
end
