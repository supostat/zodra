# frozen_string_literal: true

module RubyLsp
  module Zodra
    class CodeLensListener
      include DslDetector

      DEFINABLE_METHODS = %i[type enum union contract scalar].freeze

      def initialize(response_builder, uri, dispatcher)
        @response_builder = response_builder
        @uri = uri

        dispatcher.register(self, :on_call_node_enter)
      end

      def on_call_node_enter(node)
        return unless zodra_call?(node)

        method = zodra_method(node)
        return unless DEFINABLE_METHODS.include?(method)

        name = extract_symbol_name(node)
        return unless name

        ts_path = resolve_ts_path(method, name)
        return unless ts_path

        location = node.location

        @response_builder << RubyLsp::Interface::CodeLens.new(
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
          command: RubyLsp::Interface::Command.new(
            title: 'Open generated TypeScript',
            command: 'zodra.openGeneratedTS',
            arguments: [ts_path]
          )
        )
      end

      private

      def resolve_ts_path(method, name)
        file = file_name(name)

        case method
        when :type, :enum, :union, :scalar then "types/#{file}.ts"
        when :contract then "contracts/#{file}.ts"
        end
      end
    end
  end
end
