# frozen_string_literal: true

module Zodra
  class TypeDeriver
    def initialize(source_definition, pick: nil, omit: nil, partial: false)
      raise ArgumentError, 'Cannot use both :pick and :omit' if pick && omit
      raise ArgumentError, 'Source must be an object type' unless source_definition.object?

      @source = source_definition
      @pick = pick&.map(&:to_sym)
      @omit = omit&.map(&:to_sym)
      @partial = partial
    end

    def apply(target_definition)
      selected_attributes.each do |name, attribute|
        copy_attribute(target_definition, name, attribute, optional: @partial && !attribute.optional?)
      end
    end

    private

    def copy_attribute(target, name, attribute, optional: false)
      target.add_attribute(name,
                           type: attribute.type,
                           optional: optional || attribute.optional?,
                           nullable: attribute.nullable?,
                           format: attribute.format,
                           default: attribute.default,
                           min: attribute.min,
                           max: attribute.max,
                           enum: attribute.enum,
                           of: attribute.of,
                           reference_name: attribute.reference_name,
                           description: attribute.description,
                           deprecated: attribute.deprecated?)
    end

    def selected_attributes
      attributes = @source.attributes

      if @pick
        unknown = @pick - attributes.keys
        raise ArgumentError, "Unknown attributes #{unknown.inspect} for type :#{@source.name}" if unknown.any?

        attributes.slice(*@pick)
      elsif @omit
        unknown = @omit - attributes.keys
        raise ArgumentError, "Unknown attributes #{unknown.inspect} for type :#{@source.name}" if unknown.any?

        attributes.except(*@omit)
      else
        attributes
      end
    end
  end
end
