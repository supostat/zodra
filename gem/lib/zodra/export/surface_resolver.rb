# frozen_string_literal: true

module Zodra
  module Export
    class SurfaceResolver
      def self.call(definitions, contracts)
        return definitions if contracts.empty?

        new(definitions, contracts).resolve
      end

      def initialize(definitions, contracts)
        @definitions_by_name = definitions.each_with_object({}) { |d, h| h[d.name] = d }
        @contracts = contracts
      end

      def resolve
        reachable = expand_dependencies(collect_seed_types)
        @definitions_by_name.values.select { |d| reachable.include?(d.name) }
      end

      private

      def collect_seed_types
        names = Set.new

        @contracts.each do |contract|
          contract.actions.each_value do |action|
            names << action.response_type if action.response_type
            collect_attribute_references(action.params, names)
            collect_attribute_references(action.response_definition, names) unless action.response_type
          end
        end

        names
      end

      def expand_dependencies(seed_names)
        visited = Set.new
        queue = seed_names.to_a

        while (name = queue.shift)
          next if visited.include?(name)

          visited << name
          definition = @definitions_by_name[name]
          next unless definition

          collect_definition_dependencies(definition).each do |dep|
            queue << dep unless visited.include?(dep)
          end
        end

        visited
      end

      def collect_definition_dependencies(definition)
        deps = Set.new
        definition.attributes.each_value { |attr| add_dependency(attr, deps) }
        definition.variants.each do |variant|
          variant.attributes.each_value { |attr| add_dependency(attr, deps) }
        end
        deps
      end

      def collect_attribute_references(definition, names)
        definition.attributes.each_value { |attr| add_dependency(attr, names) }
      end

      def add_dependency(attribute, set)
        dep = attribute.dependency_name
        set << dep if dep
      end
    end
  end
end
