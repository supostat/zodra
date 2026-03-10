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

    def timestamps
      datetime :created_at
      datetime :updated_at
    end
  end
end
