# frozen_string_literal: true

module Zodra
  module Export
    class ZodMapper
      include NamingConventions

      PRIMITIVE_MAP = {
        string: 'z.string()',
        integer: 'z.number().int()',
        decimal: 'z.number()',
        number: 'z.number()',
        boolean: 'z.boolean()',
        datetime: 'z.iso.datetime()',
        date: 'z.iso.date()',
        uuid: 'z.uuid()',
        binary: 'z.string()'
      }.freeze

      def initialize(key_format: :keep)
        @key_format = key_format
      end

      def map_definition(definition, lazy: false)
        case definition.kind
        when :object then map_object(definition, lazy:)
        when :enum then map_enum(definition)
        when :union then map_union(definition, lazy:)
        end
      end

      def map_definitions(definitions, cycles: Set.new)
        definitions.map { |definition| map_definition(definition, lazy: cycles.include?(definition.name)) }.join("\n\n")
      end

      def map_contract(contract, base_path: nil)
        params_output = map_contract_params(contract)
        error_types_output = map_contract_error_types(contract)
        descriptor_output = map_contract_descriptor(contract, base_path:)
        [params_output, error_types_output, descriptor_output].compact.reject(&:empty?).join("\n\n")
      end

      def map_contracts(contracts, base_path: nil)
        contracts.map { |contract| map_contract(contract, base_path:) }.join("\n\n")
      end

      private

      def map_object(definition, lazy: false)
        name = pascal_case(definition.name)
        properties = definition.attributes.values.map { |attr| "  #{map_property(attr)}," }
        body = "z.object({\n#{properties.join("\n")}\n})"

        if lazy
          "export const #{name}Schema: z.ZodType<#{name}> = z.lazy(() => #{body});"
        else
          "export const #{name}Schema = #{body};"
        end
      end

      def map_enum(definition)
        values = definition.values.map { |value| "'#{value}'" }.join(', ')
        "export const #{pascal_case(definition.name)}Schema = z.enum([#{values}]);"
      end

      def map_union(definition, lazy: false)
        name = pascal_case(definition.name)
        discriminator_key = transform_key(definition.discriminator)
        variants = definition.variants.map { |variant| map_variant(variant, discriminator_key) }
        indent = '  '
        body = "z.discriminatedUnion('#{discriminator_key}', [\n" \
               "#{variants.map { |v| "#{indent}#{v}" }.join(",\n")},\n])"

        if lazy
          "export const #{name}Schema: z.ZodType<#{name}> = z.lazy(() => #{body});"
        else
          "export const #{name}Schema = #{body};"
        end
      end

      def map_variant(variant, discriminator_key)
        properties = variant.attributes.values.map { |attr| "#{attr.as || transform_key(attr.name)}: #{map_zod_type(attr)}" }
        all_properties = ["#{discriminator_key}: z.literal('#{variant.tag}')"] + properties
        "z.object({ #{all_properties.join(', ')} })"
      end

      def map_property(attribute)
        key = attribute.as || transform_key(attribute.name)
        "#{key}: #{map_zod_type(attribute)}"
      end

      def map_zod_type(attribute)
        base = resolve_base_type(attribute)
        base = apply_constraints(base, attribute)
        apply_modifiers(base, attribute)
      end

      def resolve_base_type(attribute)
        if attribute.enum
          values = attribute.enum.map { |v| "'#{v}'" }.join(', ')
          "z.enum([#{values}])"
        elsif attribute.enum_ref?
          "#{pascal_case(attribute.enum_type_name)}Schema"
        elsif attribute.reference?
          "#{pascal_case(attribute.reference_name)}Schema"
        elsif attribute.array?
          inner = resolve_array_element_type(attribute.of)
          "z.array(#{inner})"
        else
          resolve_primitive_type(attribute.type)
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

      def map_contract_error_types(contract)
        parts = contract.actions.values.filter_map do |action|
          next if action.errors.empty?

          action_name = pascal_case(action.name)
          contract_name = pascal_case(contract.name)

          codes = action.errors.values.map { |e| "'#{e[:code]}'" }.join(' | ')
          "export type #{action_name}#{contract_name}BusinessError = { code: #{codes}; message: string };"
        end

        parts.join("\n\n")
      end

      def map_contract_descriptor(contract, base_path: nil)
        name = pascal_case(contract.name)
        return "export const #{name}Contract = {} as const;" if contract.actions.empty?

        entries = contract.actions.values.map do |action|
          path = strip_base_path(action.path, base_path)
          params_schema = "#{pascal_case(action.name)}#{name}ParamsSchema"
          parts = ["method: '#{action.http_method.to_s.upcase}' as const", "path: '#{path}' as const",
                   "params: #{params_schema}"]
          parts << "response: #{pascal_case(action.response_type)}Schema" if action.response_type
          parts << 'collection: true as const' if action.collection?
          if action.errors.any?
            error_entries = action.errors.values.map do |e|
              "{ code: '#{e[:code]}' as const, status: #{e[:status]} as const }"
            end
            parts << "errors: [#{error_entries.join(', ')}] as const"
          end
          "  #{action.name}: { #{parts.join(', ')} }"
        end

        "export const #{name}Contract = {\n#{entries.join(",\n")},\n} as const;"
      end

      def resolve_array_element_type(element_type)
        PRIMITIVE_MAP.fetch(element_type) do
          scalar = ScalarRegistry.global.find(element_type)
          if scalar
            PRIMITIVE_MAP.fetch(scalar.base, "#{pascal_case(element_type)}Schema")
          else
            "#{pascal_case(element_type)}Schema"
          end
        end
      end

      def resolve_primitive_type(type)
        PRIMITIVE_MAP.fetch(type) do
          scalar = ScalarRegistry.global.find(type)
          scalar ? PRIMITIVE_MAP.fetch(scalar.base, 'z.unknown()') : 'z.unknown()'
        end
      end
    end
  end
end
