# frozen_string_literal: true

module Zodra
  class ApiRegistry
    include Registry

    def register(base_path)
      store_entry(base_path, ApiDefinition.new(base_path:))
    end

    private

    def normalize_key(name)
      name
    end

    def duplicate_message(key)
      "API '#{key}' is already registered"
    end
  end
end
