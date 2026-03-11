# frozen_string_literal: true

module Zodra
  class ScalarRegistry
    def self.global
      @global ||= new
    end

    def initialize
      @store = {}
    end

    def register(name, base:, coercer:)
      name = name.to_sym
      raise DuplicateTypeError, "Scalar type :#{name} is already registered" if @store.key?(name)

      @store[name] = ScalarType.new(name:, base:, coercer:)
    end

    def find(name)
      @store[name.to_sym]
    end

    def exists?(name)
      @store.key?(name.to_sym)
    end

    def clear!
      @store.clear
    end
  end
end
