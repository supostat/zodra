# frozen_string_literal: true

module RubyLsp
  module Zodra
    class DefinitionListener
      include DslDetector

      def initialize(response_builder, uri, node_context, global_state, dispatcher)
        @response_builder = response_builder
        @uri = uri
        @node_context = node_context
        @index = global_state.index

        dispatcher.register(self, :on_symbol_node_enter)
      end

      def on_symbol_node_enter(node)
        call_node = @node_context.call_node
        return unless call_node
        return unless cross_reference_context?(call_node)

        type_name = node.value
        return unless type_name

        resolve_definition(type_name)
      end

      private

      def cross_reference_context?(call_node)
        return true if cross_reference_call?(call_node)
        return true if keyword_argument_reference?(call_node)
        return true if zodra_call?(call_node) && keyword_reference_in_args?(call_node)

        false
      end

      def keyword_reference_in_args?(call_node)
        keyword_args = extract_keyword_arguments(call_node)
        keyword_args.key?(:from) || keyword_args.key?(:of) || keyword_args.key?(:contract)
      end

      def resolve_definition(type_name)
        entry_name = find_type_entry_name(type_name)
        return unless entry_name

        entries = @index[entry_name]
        return unless entries&.any?

        entry = entries.first
        location = entry.location

        @response_builder << RubyLsp::Interface::Location.new(
          uri: entry.uri.to_s,
          range: RubyLsp::Interface::Range.new(
            start: RubyLsp::Interface::Position.new(
              line: location.start_line - 1,
              character: location.start_column
            ),
            end: RubyLsp::Interface::Position.new(
              line: location.end_line - 1,
              character: location.end_column
            )
          )
        )
      end

      def find_type_entry_name(name)
        # Check contracts first (for `resources :products`)
        %w[Type Enum Union Contract Scalar].each do |category|
          entry_name = "Zodra::#{category}::#{pascal_case(name)}"
          return entry_name if @index[entry_name]
        end
        nil
      end
    end
  end
end
