# frozen_string_literal: true

module Zodra
  class VariantBuilder
    attr_reader :attributes

    PRIMITIVES = TypeBuilder::PRIMITIVES

    def initialize
      @attributes = {}
    end

    PRIMITIVES.each do |primitive_type|
      define_method(primitive_type) do |name, **options|
        @attributes[name.to_sym] = Attribute.new(name:, type: primitive_type, **options)
      end

      define_method(:"#{primitive_type}?") do |name, **options|
        @attributes[name.to_sym] = Attribute.new(name:, type: primitive_type, optional: true, **options)
      end
    end
  end
end
