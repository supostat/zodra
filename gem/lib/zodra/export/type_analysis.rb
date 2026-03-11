# frozen_string_literal: true

module Zodra
  module Export
    class TypeAnalysis
      Result = Data.define(:sorted, :cycles)

      def self.call(definitions)
        new(definitions).analyze
      end

      def initialize(definitions)
        @definitions_by_name = definitions.each_with_object({}) { |d, h| h[d.name] = d }
        @graph = build_graph
      end

      def analyze
        cycles = detect_cycles
        sorted = topological_sort(cycles)
        Result.new(sorted:, cycles:)
      end

      private

      def build_graph
        @definitions_by_name.each_with_object({}) do |(name, definition), graph|
          graph[name] = collect_dependencies(definition)
        end
      end

      def collect_dependencies(definition)
        deps = Set.new

        definition.attributes.each_value do |attr|
          dep = attr.dependency_name
          deps << dep if dep && @definitions_by_name.key?(dep)
        end

        definition.variants.each do |variant|
          variant.attributes.each_value do |attr|
            dep = attr.dependency_name
            deps << dep if dep && @definitions_by_name.key?(dep)
          end
        end

        deps
      end

      # Tarjan's SCC algorithm — detects strongly connected components
      def detect_cycles
        @index_counter = 0
        @stack = []
        @indices = {}
        @lowlinks = {}
        @on_stack = Set.new
        cycles = Set.new

        @graph.each_key do |name|
          tarjan(name, cycles) unless @indices.key?(name)
        end

        cycles
      end

      def tarjan(name, cycles)
        @indices[name] = @index_counter
        @lowlinks[name] = @index_counter
        @index_counter += 1
        @stack.push(name)
        @on_stack << name

        @graph[name].each do |dep|
          if !@indices.key?(dep)
            tarjan(dep, cycles)
            @lowlinks[name] = [@lowlinks[name], @lowlinks[dep]].min
          elsif @on_stack.include?(dep)
            @lowlinks[name] = [@lowlinks[name], @indices[dep]].min
          end
        end

        return unless @lowlinks[name] == @indices[name]

        component = []
        loop do
          node = @stack.pop
          @on_stack.delete(node)
          component << node
          break if node == name
        end

        return unless component.size > 1 || @graph[name].include?(name)

        component.each { |n| cycles << n }
      end

      # Kahn's algorithm with reversed edges — dependencies come before dependents
      def topological_sort(cycles)
        in_degree = Hash.new(0)
        reverse_adjacency = {}

        @graph.each_key do |name|
          reverse_adjacency[name] ||= []
        end

        @graph.each do |name, deps|
          deps.each do |dep|
            next if cycles.include?(name) && cycles.include?(dep)

            reverse_adjacency[dep] ||= []
            reverse_adjacency[dep] << name
            in_degree[name] += 1
          end
        end

        queue = @graph.keys.select { |n| in_degree[n] == 0 }
        sorted = []

        while (name = queue.shift)
          sorted << name
          reverse_adjacency[name]&.each do |dependent|
            in_degree[dependent] -= 1
            queue << dependent if in_degree[dependent] == 0
          end
        end

        remaining = @graph.keys - sorted
        sorted.concat(remaining)

        sorted.filter_map { |name| @definitions_by_name[name] }
      end
    end
  end
end
