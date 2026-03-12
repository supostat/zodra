# frozen_string_literal: true

# NOTE: ruby-lsp 0.26.x does not expose a factory method for diagnostics listeners.
# This file is prepared for when the API supports it. Not loaded by the addon.

module RubyLsp
  module Zodra
    class DiagnosticsListener
      include DslDetector

      def initialize(response_builder, global_state, dispatcher)
        @response_builder = response_builder
        @index = global_state.index

        dispatcher.register(self, :on_call_node_enter)
      end

      def on_call_node_enter(node)
        check_pick_omit_conflict(node)
        check_empty_enum_values(node)
      end

      private

      def check_pick_omit_conflict(node)
        return unless zodra_call?(node) && zodra_method(node) == :type

        keyword_args = extract_keyword_arguments(node)
        return unless keyword_args[:pick] && keyword_args[:omit]

        location = node.location

        @response_builder << RubyLsp::Interface::Diagnostic.new(
          range: RubyLsp::Interface::Range.new(
            start: RubyLsp::Interface::Position.new(
              line: location.start_line - 1,
              character: location.start_column
            ),
            end: RubyLsp::Interface::Position.new(
              line: location.end_line - 1,
              character: location.end_column
            )
          ),
          message: 'Cannot use both pick: and omit: together',
          severity: RubyLsp::Constant::DiagnosticSeverity::ERROR,
          source: 'zodra'
        )
      end

      def check_empty_enum_values(node)
        return unless zodra_call?(node) && zodra_method(node) == :enum

        keyword_args = extract_keyword_arguments(node)
        values = keyword_args[:values]
        return unless values.is_a?(Prism::ArrayNode) && values.elements.empty?

        location = values.location

        @response_builder << RubyLsp::Interface::Diagnostic.new(
          range: RubyLsp::Interface::Range.new(
            start: RubyLsp::Interface::Position.new(
              line: location.start_line - 1,
              character: location.start_column
            ),
            end: RubyLsp::Interface::Position.new(
              line: location.end_line - 1,
              character: location.end_column
            )
          ),
          message: 'Enum values should not be empty',
          severity: RubyLsp::Constant::DiagnosticSeverity::WARNING,
          source: 'zodra'
        )
      end
    end
  end
end
