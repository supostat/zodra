# frozen_string_literal: true

require "fileutils"

module Zodra
  module Export
    class Writer
      FORMATS = {
        zod: "schemas.ts",
        typescript: "types.ts"
      }.freeze

      def initialize(configuration)
        @configuration = configuration
      end

      def write(format)
        content = Export.generate(format,
                                 key_format: @configuration.key_format,
                                 zod_import: @configuration.zod_import)

        FileUtils.mkdir_p(@configuration.output_path)
        filepath = File.join(@configuration.output_path, FORMATS.fetch(format))
        File.write(filepath, content)
        filepath
      end

      def write_all
        FORMATS.keys.map { |format| write(format) }
      end
    end
  end
end
