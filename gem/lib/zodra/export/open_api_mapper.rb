# frozen_string_literal: true

require 'json'

module Zodra
  module Export
    class OpenApiMapper
      include NamingConventions

      PRIMITIVE_MAP = {
        string: { type: 'string' },
        integer: { type: 'integer' },
        decimal: { type: 'number' },
        number: { type: 'number' },
        boolean: { type: 'boolean' },
        datetime: { type: 'string', format: 'date-time' },
        date: { type: 'string', format: 'date' },
        uuid: { type: 'string', format: 'uuid' },
        binary: { type: 'string', format: 'binary' }
      }.freeze

      def initialize(definitions:, contracts:, base_path: nil, config: Configuration.new)
        @definitions = definitions
        @contracts = contracts
        @base_path = base_path
        @config = config
        @key_format = config.key_format
      end

      def generate
        doc = {
          openapi: '3.1.0',
          info: build_info
        }
        doc[:servers] = build_servers if @base_path
        doc[:paths] = build_paths
        doc[:components] = { schemas: build_schemas }
        doc
      end

      def to_json(*_args)
        JSON.pretty_generate(generate)
      end

      private

      def build_info
        info = { title: @config.openapi_title || 'API', version: @config.openapi_version || '0.0.1' }
        info[:description] = @config.openapi_description if @config.openapi_description
        info
      end

      def build_servers
        [{ url: @base_path }]
      end

      def build_paths
        paths = {}

        @contracts.each do |contract|
          contract.actions.each_value do |action|
            path = openapi_path(action.path)
            method = action.http_method.to_s.downcase
            paths[path] ||= {}
            paths[path][method] = build_operation(action, contract)
          end
        end

        paths
      end

      def build_operation(action, contract)
        operation = {
          operationId: "#{action.name}_#{contract.name}",
          responses: build_responses(action)
        }
        operation[:summary] = action.description if action.description
        operation[:deprecated] = true if action.deprecated?

        path_params = extract_path_params(action.path)
        query_or_body_params = action.params.attributes.values.reject { |a| path_params.include?(a.name.to_s) }

        parameters = path_params.map { |name| build_path_parameter(name) }

        if %i[get delete].include?(action.http_method) && query_or_body_params.any?
          parameters += query_or_body_params.map { |attr| build_query_parameter(attr) }
        end

        operation[:parameters] = parameters if parameters.any?

        operation[:requestBody] = build_request_body(query_or_body_params) if %i[post put patch].include?(action.http_method) && query_or_body_params.any?

        operation
      end

      def build_responses(action)
        responses = {}

        if action.response_type || action.response_definition.attributes.any?
          response_schema = build_response_schema(action)
          responses['200'] = {
            description: 'Successful response',
            content: { 'application/json' => { schema: response_schema } }
          }
        else
          responses['200'] = { description: 'Successful response' }
        end

        build_error_responses(action, responses)
        responses
      end

      def build_response_schema(action)
        schema = if action.response_type
                   ref_schema(action.response_type)
                 else
                   map_definition_inline(action.response_definition)
                 end

        if action.collection?
          {
            type: 'object',
            properties: {
              data: { type: 'array', items: schema },
              meta: { type: 'object' }
            },
            required: %w[data]
          }
        else
          { type: 'object', properties: { data: schema }, required: %w[data] }
        end
      end

      def build_error_responses(action, responses)
        return if action.errors.empty?

        action.errors.each_value { |error| add_error_response(responses, error) }
      end

      def add_error_response(responses, error)
        status = error[:status].to_s

        if responses[status]
          responses[status].dig(:content, 'application/json', :schema, :properties, :error, :properties, :code, :enum) << error[:code].to_s
        else
          responses[status] = {
            description: "Error: #{error[:code]}",
            content: { 'application/json' => { schema: build_error_schema(error[:code]) } }
          }
        end
      end

      def build_error_schema(code)
        {
          type: 'object',
          properties: {
            error: {
              type: 'object',
              properties: { code: { type: 'string', enum: [code.to_s] }, message: { type: 'string' } },
              required: %w[code message]
            }
          },
          required: %w[error]
        }
      end

      def build_path_parameter(name)
        { name: name, in: 'path', required: true, schema: { type: 'string' } }
      end

      def build_query_parameter(attribute)
        param = { name: transform_key(attribute.name), in: 'query', schema: map_attribute_type(attribute) }
        param[:required] = true unless attribute.optional?
        param[:description] = attribute.description if attribute.description
        param[:deprecated] = true if attribute.deprecated?
        param
      end

      def build_request_body(attributes)
        required = attributes.reject(&:optional?).map { |a| transform_key(a.name) }
        properties = attributes.to_h { |a| [transform_key(a.name), map_attribute_type(a)] }

        schema = { type: 'object', properties: properties }
        schema[:required] = required if required.any?

        { required: true, content: { 'application/json' => { schema: schema } } }
      end

      def build_schemas
        schemas = {}

        @definitions.each do |definition|
          name = pascal_case(definition.name)
          schemas[name] = map_definition_schema(definition)
        end

        schemas
      end

      def map_definition_schema(definition)
        case definition.kind
        when :object then map_object_schema(definition)
        when :enum then map_enum_schema(definition)
        when :union then map_union_schema(definition)
        end
      end

      def map_object_schema(definition)
        properties = {}
        required = []

        definition.attributes.each_value do |attr|
          key = transform_key(attr.name)
          properties[key] = map_attribute_type(attr)
          required << key unless attr.optional?
        end

        schema = { type: 'object', properties: properties }
        schema[:required] = required if required.any?
        schema[:description] = definition.description if definition.description
        schema
      end

      def map_enum_schema(definition)
        schema = { type: 'string', enum: definition.values.map(&:to_s) }
        schema[:description] = definition.description if definition.description
        schema
      end

      def map_union_schema(definition)
        discriminator_key = transform_key(definition.discriminator)
        variants = definition.variants.map { |v| map_variant_schema(v, discriminator_key) }

        schema = {
          oneOf: variants,
          discriminator: { propertyName: discriminator_key }
        }
        schema[:description] = definition.description if definition.description
        schema
      end

      def map_variant_schema(variant, discriminator_key)
        properties = { discriminator_key => { type: 'string', enum: [variant.tag.to_s] } }
        required = [discriminator_key]

        variant.attributes.each_value do |attr|
          key = attr.as || transform_key(attr.name)
          properties[key] = map_attribute_type(attr)
          required << key unless attr.optional?
        end

        { type: 'object', properties: properties, required: required }
      end

      def map_attribute_type(attribute)
        schema = resolve_base_type(attribute)
        schema = apply_constraints(schema, attribute)
        schema = apply_metadata(schema, attribute)
        apply_nullable(schema, attribute)
      end

      def resolve_base_type(attribute)
        if attribute.enum
          { type: 'string', enum: attribute.enum.map(&:to_s) }
        elsif attribute.enum_ref?
          ref_schema(attribute.enum_type_name)
        elsif attribute.reference?
          ref_schema(attribute.reference_name)
        elsif attribute.array?
          { type: 'array', items: resolve_array_element(attribute.of) }
        else
          resolve_primitive(attribute.type)
        end
      end

      def apply_constraints(schema, attribute)
        return schema if schema.key?(:$ref)

        schema = schema.dup
        if %w[string].include?(schema[:type])
          schema[:minLength] = attribute.min if attribute.min
          schema[:maxLength] = attribute.max if attribute.max
        else
          schema[:minimum] = attribute.min if attribute.min
          schema[:maximum] = attribute.max if attribute.max
        end
        schema[:default] = attribute.default unless attribute.default.nil?
        schema
      end

      def apply_metadata(schema, attribute)
        return schema if schema.key?(:$ref)

        schema = schema.dup
        schema[:description] = attribute.description if attribute.description
        schema[:deprecated] = true if attribute.deprecated?
        schema
      end

      def apply_nullable(schema, attribute)
        return schema unless attribute.nullable?

        if schema.key?(:$ref)
          { oneOf: [schema, { type: 'null' }] }
        else
          schema = schema.dup
          current_type = schema[:type]
          schema[:type] = [current_type, 'null'] if current_type.is_a?(String)
          schema
        end
      end

      def ref_schema(type_name)
        { :$ref => "#/components/schemas/#{pascal_case(type_name)}" }
      end

      def resolve_array_element(element_type)
        PRIMITIVE_MAP.fetch(element_type) do
          scalar = ScalarRegistry.global.find(element_type)
          if scalar
            PRIMITIVE_MAP.fetch(scalar.base, ref_schema(element_type))
          else
            ref_schema(element_type)
          end
        end
      end

      def resolve_primitive(type)
        PRIMITIVE_MAP.fetch(type) do
          scalar = ScalarRegistry.global.find(type)
          scalar ? PRIMITIVE_MAP.fetch(scalar.base, { type: 'string' }) : { type: 'string' }
        end
      end

      def map_definition_inline(definition)
        properties = {}
        definition.attributes.each_value do |attr|
          key = transform_key(attr.name)
          properties[key] = map_attribute_type(attr)
        end
        { type: 'object', properties: properties }
      end

      def transform_key(key)
        key_string = key.to_s
        case @key_format
        when :camel then camel_case(key_string)
        when :pascal then pascal_case(key_string)
        else key_string
        end
      end

      def openapi_path(path)
        return path unless path

        stripped = @base_path ? path.delete_prefix(@base_path) : path
        stripped.gsub(/:(\w+)/, '{\1}')
      end

      def extract_path_params(path)
        return [] unless path

        path.scan(/:(\w+)/).flatten
      end
    end
  end
end
