# frozen_string_literal: true

module Zodra
  module Export
    MAPPERS = {
      typescript: TypeScriptMapper,
      zod: ZodMapper
    }.freeze

    def self.generate(format, key_format: :camel, zod_import: "zod")
      mapper_class = MAPPERS.fetch(format) do
        raise ConfigurationError, "Unknown export format: #{format}. Available: #{MAPPERS.keys.join(', ')}"
      end

      mapper = mapper_class.new(key_format:)
      contracts = ContractRegistry.global.to_a

      definitions = SurfaceResolver.call(TypeRegistry.global.to_a, contracts)
      analysis = TypeAnalysis.call(definitions)

      parts = []
      parts << "import { z } from '#{zod_import}';" if format == :zod
      parts << mapper.map_definitions(analysis.sorted, cycles: analysis.cycles)
      parts << mapper.map_contracts(contracts) unless contracts.empty?
      parts.reject(&:empty?).join("\n\n")
    end

    def self.generate_contracts
      contracts = ContractRegistry.global.to_a
      api_definitions = ApiRegistry.global.to_a

      ContractMapper.new(api_definitions, contracts).generate
    end
  end
end
