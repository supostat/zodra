# frozen_string_literal: true

module Zodra
  class ApiRegistry
    include Enumerable

    def self.global
      @global ||= new
    end

    def initialize
      @store = {}
    end

    def register(base_path)
      raise DuplicateTypeError, "API '#{base_path}' is already registered" if @store.key?(base_path)

      @store[base_path] = ApiDefinition.new(base_path:)
    end

    def find(base_path)
      @store[base_path]
    end

    def each(&)
      @store.each_value(&)
    end

    def clear!
      @store.clear
    end
  end
end
