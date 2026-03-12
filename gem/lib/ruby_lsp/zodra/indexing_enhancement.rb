# frozen_string_literal: true

require_relative 'dsl_detector'

module RubyLsp
  module Zodra
    class IndexingEnhancement < RubyIndexer::Enhancement
      include DslDetector

      INDEXABLE_METHODS = %i[type enum union contract scalar].freeze

      def on_call_node_enter(node)
        return unless zodra_call?(node)

        method = zodra_method(node)
        return unless INDEXABLE_METHODS.include?(method)

        name = extract_symbol_name(node)
        return unless name

        nesting = build_nesting(method, name)
        @listener.add_class(nesting, node.location, node.location)
      end

      def on_call_node_leave(node)
        return unless zodra_call?(node)
        return unless INDEXABLE_METHODS.include?(zodra_method(node))
        return unless extract_symbol_name(node)

        @listener.pop_namespace_stack
      end

      private

      def build_nesting(method, name)
        category = method.to_s.capitalize
        pascal = pascal_case(name)
        ['Zodra', category, pascal]
      end
    end
  end
end
