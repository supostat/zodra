# frozen_string_literal: true

module RubyLsp
  module Zodra
    class CompletionListener
      include DslDetector

      def initialize(response_builder, node_context, global_state, dispatcher)
        @response_builder = response_builder
        @node_context = node_context
        @index = global_state.index

        dispatcher.register(self, :on_symbol_node_enter)
      end

      def on_symbol_node_enter(node)
        call_node = @node_context.call_node
        return unless call_node
        return unless cross_reference_context?(call_node)

        prefix = node.value || ''
        complete_type_names(prefix, node)
      end

      private

      def cross_reference_context?(call_node)
        cross_reference_call?(call_node) || keyword_reference_context?(call_node)
      end

      def keyword_reference_context?(call_node)
        return false unless zodra_call?(call_node)

        keyword_args = extract_keyword_arguments(call_node)
        keyword_args.key?(:from) || keyword_args.key?(:of) || keyword_args.key?(:contract)
      end

      def complete_type_names(prefix, node)
        %w[Type Enum Union Scalar].each do |category|
          search_prefix = "Zodra::#{category}::#{pascal_case(prefix)}"
          candidates = @index.prefix_search(search_prefix)

          candidates.flatten.each do |entry|
            short_name = entry.name.split('::').last
            next unless short_name

            symbol_name = short_name
                          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                          .downcase

            range = range_from_symbol_node(node)

            @response_builder << RubyLsp::Interface::CompletionItem.new(
              label: symbol_name,
              filter_text: symbol_name,
              label_details: RubyLsp::Interface::CompletionItemLabelDetails.new(
                description: "Zodra #{category.downcase}"
              ),
              text_edit: RubyLsp::Interface::TextEdit.new(
                range: range,
                new_text: symbol_name
              ),
              kind: RubyLsp::Constant::CompletionItemKind::REFERENCE
            )
          end
        end
      end

      def range_from_symbol_node(node)
        location = node.value_loc || node.location

        RubyLsp::Interface::Range.new(
          start: RubyLsp::Interface::Position.new(
            line: location.start_line - 1,
            character: location.start_column
          ),
          end: RubyLsp::Interface::Position.new(
            line: location.end_line - 1,
            character: location.end_column
          )
        )
      end
    end
  end
end
