# frozen_string_literal: true

module Zodra
  module Registry
    include Enumerable

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def global
        @global ||= new
      end
    end

    def initialize
      @store = {}
    end

    def find(name)
      @store[normalize_key(name)]
    end

    def exists?(name)
      @store.key?(normalize_key(name))
    end

    def each(&)
      @store.each_value(&)
    end

    def clear!
      @store.clear
    end

    private

    def normalize_key(name)
      name.to_sym
    end

    def store_entry(key, value)
      raise DuplicateTypeError, duplicate_message(key) if @store.key?(key)

      @store[key] = value
    end
  end
end
