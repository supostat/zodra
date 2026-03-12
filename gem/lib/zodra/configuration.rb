# frozen_string_literal: true

module Zodra
  class Configuration
    DEFAULTS = {
      output_path: 'app/javascript/types',
      key_format: :camel,
      zod_import: 'zod',
      strict_params: true,
      openapi_title: nil,
      openapi_version: nil,
      openapi_description: nil
    }.freeze

    attr_accessor :output_path, :key_format, :zod_import, :strict_params,
                  :openapi_title, :openapi_version, :openapi_description

    def initialize
      DEFAULTS.each { |key, value| public_send(:"#{key}=", value) }
    end
  end
end
