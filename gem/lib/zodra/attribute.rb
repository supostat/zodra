# frozen_string_literal: true

module Zodra
  class Attribute
    attr_reader :name, :type, :format, :default, :min, :max, :enum, :of, :reference_name, :enum_type_name, :as,
                :description

    def initialize(name:, type:, optional: false, nullable: false, format: nil,
                   default: nil, min: nil, max: nil, enum: nil, of: nil, reference_name: nil,
                   enum_type_name: nil, as: nil, description: nil, deprecated: false)
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
      @enum_type_name = enum_type_name
      @as = as&.to_s
      @description = description
      @deprecated = deprecated
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

    def deprecated?
      @deprecated
    end

    def enum_ref?
      !@enum_type_name.nil?
    end

    def dependency_name
      if reference?
        reference_name.to_sym
      elsif array? && of
        of.to_sym
      elsif enum_ref?
        enum_type_name.to_sym
      end
    end
  end
end
