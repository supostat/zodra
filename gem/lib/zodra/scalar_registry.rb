# frozen_string_literal: true

module Zodra
  class ScalarRegistry
    include Registry

    def register(name, base:, coercer:)
      key = normalize_key(name)
      store_entry(key, ScalarType.new(name:, base:, coercer:))
    end

    private

    def duplicate_message(key)
      "Scalar type :#{key} is already registered"
    end
  end
end
