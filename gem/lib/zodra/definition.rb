# frozen_string_literal: true

module Zodra
  class Definition
    attr_reader :name, :kind, :discriminator, :values, :attributes, :variants

    def initialize(name:, kind:, discriminator: nil, values: nil)
      @name = name
      @kind = kind
      @discriminator = discriminator
      @values = values
      @attributes = {}
      @variants = []
    end

    def object?
      kind == :object
    end

    def enum?
      kind == :enum
    end

    def union?
      kind == :union
    end

    def add_attribute(attribute_name, **options)
      @attributes[attribute_name.to_sym] = Attribute.new(name: attribute_name, **options)
    end

    def add_variant(tag, attributes: {})
      @variants << Variant.new(tag:, attributes:)
    end
  end
end
