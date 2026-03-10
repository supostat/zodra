# frozen_string_literal: true

module Zodra
  class UnionBuilder
    def initialize(definition)
      @definition = definition
    end

    def variant(tag, &block)
      variant_builder = VariantBuilder.new
      variant_builder.instance_eval(&block) if block
      @definition.add_variant(tag, attributes: variant_builder.attributes)
    end
  end
end
