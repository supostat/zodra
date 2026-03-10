# frozen_string_literal: true

module Zodra
  class Attribute
    attr_reader :name, :type, :format, :default, :min, :max, :enum, :of, :reference_name

    def initialize(name:, type:, optional: false, nullable: false, format: nil,
                   default: nil, min: nil, max: nil, enum: nil, of: nil, reference_name: nil)
      @name = name.to_sym
      @type = type.to_sym
      @optional = optional
      @nullable = nullable
      @format = format
      @default = default
      @min = min
      @max = max
      @enum = enum
      @of = of
      @reference_name = reference_name
    end

    def optional?
      @optional
    end

    def nullable?
      @nullable
    end

    def reference?
      type == :reference
    end

    def array?
      type == :array
    end
  end
end
