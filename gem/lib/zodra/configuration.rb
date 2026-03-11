# frozen_string_literal: true

module Zodra
  class Configuration
    DEFAULTS = {
      output_path: "app/javascript/types",
      key_format: :camel,
      zod_import: "zod",
      strict_params: true
    }.freeze

    attr_accessor :output_path, :key_format, :zod_import, :strict_params

    def initialize
      DEFAULTS.each { |key, value| public_send(:"#{key}=", value) }
    end
  end
end
