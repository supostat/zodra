# frozen_string_literal: true

module Zodra
  class ScalarType
    attr_reader :name, :base, :coercer

    def initialize(name:, base:, coercer:)
      @name = name.to_sym
      @base = base.to_sym
      @coercer = coercer
    end
  end
end
