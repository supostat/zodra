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

      parts = []
      parts << "import { z } from '#{zod_import}';" if format == :zod
      parts << mapper.map_definitions(TypeRegistry.global.to_a)
      parts << mapper.map_contracts(contracts) unless contracts.empty?
      parts.reject(&:empty?).join("\n\n")
    end
  end
end
