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
      definitions = TypeRegistry.global.to_a

      header = format == :zod ? "import { z } from '#{zod_import}';\n\n" : ""
      header + mapper.map_definitions(definitions)
    end
  end
end
