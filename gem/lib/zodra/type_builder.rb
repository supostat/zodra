# frozen_string_literal: true

module Zodra
  class TypeBuilder
    PRIMITIVES = %i[string integer decimal boolean datetime date uuid binary number].freeze

    def initialize(definition)
      @definition = definition
    end

    PRIMITIVES.each do |primitive_type|
      define_method(primitive_type) do |name, **options|
        @definition.add_attribute(name, type: primitive_type, **options)
      end

      define_method(:"#{primitive_type}?") do |name, **options|
        @definition.add_attribute(name, type: primitive_type, optional: true, **options)
      end
    end

    def reference(name, to: nil)
      target = to || name
      @definition.add_attribute(name, type: :reference, reference_name: target)
    end

    def array(name, of: nil, **options)
      @definition.add_attribute(name, type: :array, of:, **options)
    end

    def from(type_name, pick: nil, omit: nil, partial: false)
      source = TypeRegistry.global.find!(type_name)
      TypeDeriver.new(source, pick:, omit:, partial:).apply(@definition)
    end

    def timestamps
      datetime :created_at
      datetime :updated_at
    end

    def method_missing(method_name, *args, **options, &block)
      name_string = method_name.to_s
      optional = name_string.end_with?("?")
      scalar_name = optional ? name_string.delete_suffix("?").to_sym : method_name

      if ScalarRegistry.global.exists?(scalar_name)
        @definition.add_attribute(args.first, type: scalar_name, optional:, **options)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      scalar_name = method_name.to_s.delete_suffix("?").to_sym
      ScalarRegistry.global.exists?(scalar_name) || super
    end
  end
end
