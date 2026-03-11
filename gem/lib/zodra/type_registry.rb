# frozen_string_literal: true

module Zodra
  class TypeRegistry
    include Enumerable

    def self.global
      @global ||= new
    end

    def initialize
      @store = {}
    end

    def register(name, kind:, **)
      store(name, Definition.new(name: name.to_sym, kind:, **))
    end

    def store(name, definition)
      name = name.to_sym
      raise DuplicateTypeError, "Type :#{name} is already registered" if @store.key?(name)

      @store[name] = definition
    end

    def find(name)
      @store[name.to_sym]
    end

    def find!(name)
      @store.fetch(name.to_sym) { raise KeyError, "Type :#{name} is not registered" }
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
