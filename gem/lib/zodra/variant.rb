# frozen_string_literal: true

module Zodra
  class Variant
    attr_reader :tag, :attributes

    def initialize(tag:, attributes: {})
      @tag = tag.to_sym
      @attributes = attributes
    end
  end
end
