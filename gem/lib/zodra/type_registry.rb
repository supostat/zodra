# frozen_string_literal: true

module Zodra
  class TypeRegistry
    include Registry

    def register(name, kind:, **)
      store(name, Definition.new(name: name.to_sym, kind:, **))
    end

    def store(name, definition)
      key = normalize_key(name)
      store_entry(key, definition)
    end

    def find!(name)
      @store.fetch(normalize_key(name)) { raise KeyError, "Type :#{name} is not registered" }
    end

    private

    def duplicate_message(key)
      "Type :#{key} is already registered"
    end
  end
end
