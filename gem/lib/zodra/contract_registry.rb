# frozen_string_literal: true

module Zodra
  class ContractRegistry
    include Registry

    def register(name)
      key = normalize_key(name)
      store_entry(key, Contract.new(name:))
    end

    def find!(name)
      @store.fetch(normalize_key(name)) { raise KeyError, "Contract :#{name} is not registered" }
    end

    private

    def duplicate_message(key)
      "Contract :#{key} is already registered"
    end
  end
end
