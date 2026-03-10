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

    def register(name, kind:, **options)
      name = name.to_sym
      raise DuplicateTypeError, "Type :#{name} is already registered" if @store.key?(name)

      @store[name] = Definition.new(name:, kind:, **options)
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

    def each(&block)
      @store.each_value(&block)
    end

    def clear!
      @store.clear
    end
  end
end
