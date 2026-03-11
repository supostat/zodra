# frozen_string_literal: true

module Zodra
  class ContractRegistry
    include Enumerable

    def self.global
      @global ||= new
    end

    def initialize
      @store = {}
    end

    def register(name)
      name = name.to_sym
      raise DuplicateTypeError, "Contract :#{name} is already registered" if @store.key?(name)

      @store[name] = Contract.new(name:)
    end

    def find(name)
      @store[name.to_sym]
    end

    def find!(name)
      @store.fetch(name.to_sym) { raise KeyError, "Contract :#{name} is not registered" }
    end

    def exists?(name)
      @store.key?(name.to_sym)
    end

    def each(&)
      @store.each_value(&)
    end

    def clear!
      @store.clear
    end
  end
end
