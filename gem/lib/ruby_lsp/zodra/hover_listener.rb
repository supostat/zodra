# frozen_string_literal: true

module RubyLsp
  module Zodra
    class HoverListener
      include DslDetector

      def initialize(response_builder, node_context, global_state, dispatcher)
        @response_builder = response_builder
        @node_context = node_context
        @index = global_state.index

        dispatcher.register(self, :on_call_node_enter, :on_symbol_node_enter)
      end

      def on_call_node_enter(node)
        if zodra_call?(node)
          hover_zodra_definition(node)
        elsif node.receiver.nil? && primitive?(node.name)
          hover_primitive(node.name)
        end
      end

      def on_symbol_node_enter(node)
        call_node = @node_context.call_node
        return unless call_node

        if cross_reference_call?(call_node)
          hover_type_reference(node)
        elsif zodra_call?(call_node)
          hover_zodra_definition_name(call_node, node)
        end
      end

      private

      def hover_zodra_definition(node)
        method = zodra_method(node)
        name = extract_symbol_name(node) || extract_string_name(node)
        return unless name

        @response_builder.push(
          "```ruby\nZodra.#{method} :#{name}\n```",
          category: :title
        )

        entry_name = index_entry_name(method, name)
        entries = @index[entry_name]
        return unless entries&.any?

        file = entries.first.file_name
        @response_builder.push("Defined in `#{file}`", category: :documentation)
      end

      def hover_zodra_definition_name(call_node, symbol_node)
        method = zodra_method(call_node)
        name = symbol_node.value
        return unless name

        entry_name = index_entry_name(method, name)
        entries = @index[entry_name]
        return unless entries&.any?

        @response_builder.push(
          "```ruby\nZodra.#{method} :#{name}\n```",
          category: :title
        )
        @response_builder.push("Defined in `#{entries.first.file_name}`", category: :documentation)
      end

      def hover_type_reference(symbol_node)
        type_name = symbol_node.value
        return unless type_name

        entry_name = find_type_entry_name(type_name)
        entries = entry_name && @index[entry_name]

        return unless entries&.any?

        entry = entries.first
        @response_builder.push(
          "**Zodra type** `:#{type_name}`",
          category: :title
        )
        @response_builder.push("Defined in `#{entry.file_name}`", category: :documentation)
      end

      def hover_primitive(name)
        base_name = name.to_s.delete_suffix('?').to_sym
        info = PRIMITIVES[base_name]
        return unless info

        optional = name.to_s.end_with?('?') ? ' (optional)' : ''

        @response_builder.push(
          "**#{base_name}**#{optional}",
          category: :title
        )
        @response_builder.push(
          "Zod: `#{info[:zod]}` | TypeScript: `#{info[:ts]}`" \
          "#{"\n\nOptions: #{info[:options]}" if info[:options]}",
          category: :documentation
        )
      end

      def find_type_entry_name(name)
        %w[Type Enum Union Scalar].each do |category|
          entry_name = "Zodra::#{category}::#{pascal_case(name)}"
          return entry_name if @index[entry_name]
        end
        nil
      end
    end
  end
end
