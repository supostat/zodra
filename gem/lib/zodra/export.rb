# frozen_string_literal: true

module Zodra
  module Export
    MAPPERS = {
      typescript: TypeScriptMapper,
      zod: ZodMapper
    }.freeze

    def self.generate(format, key_format: :camel, zod_import: 'zod')
      mapper_class = MAPPERS.fetch(format) do
        raise ConfigurationError, "Unknown export format: #{format}. Available: #{MAPPERS.keys.join(', ')}"
      end

      mapper = mapper_class.new(key_format:)
      contracts = ContractRegistry.global.to_a
      base_path = ApiRegistry.global.to_a.first&.base_path

      definitions = SurfaceResolver.call(TypeRegistry.global.to_a, contracts)
      analysis = TypeAnalysis.call(definitions)

      parts = []
      parts << "import { z } from '#{zod_import}';" if format == :zod
      parts << mapper.map_definitions(analysis.sorted, cycles: analysis.cycles)
      parts << mapper.map_contracts(contracts, base_path:) unless contracts.empty?
      parts.reject(&:empty?).join("\n\n")
    end

    def self.generate_openapi(config: Zodra.configuration)
      all_contracts = ContractRegistry.global.to_a
      api_definitions = ApiRegistry.global.to_a

      if api_definitions.any?
        api_definitions.to_h do |api_def|
          contracts = collect_api_contracts(api_def, all_contracts)
          doc = build_openapi_document(contracts, base_path: api_def.base_path, config:)
          slug = api_def.base_path.tr('/', '-').delete_prefix('-')
          [slug, doc]
        end
      else
        contracts = all_contracts.select(&:openapi?)
        { 'api' => build_openapi_document(contracts, config:) }
      end
    end

    def self.build_openapi_document(contracts, base_path: nil, config: Zodra.configuration)
      definitions = SurfaceResolver.call(TypeRegistry.global.to_a, contracts)
      sorted = TypeAnalysis.call(definitions).sorted

      OpenApiMapper.new(definitions: sorted, contracts:, base_path:, config:).generate
    end

    def self.collect_api_contracts(api_definition, all_contracts)
      contract_names = api_definition.resources.map(&:contract_name)
      all_contracts.select { |c| contract_names.include?(c.name) && c.openapi? }
    end

    private_class_method :build_openapi_document, :collect_api_contracts

    def self.generate_contracts
      contracts = ContractRegistry.global.to_a
      api_definitions = ApiRegistry.global.to_a

      ContractMapper.new(api_definitions, contracts).generate
    end
  end
end
