# frozen_string_literal: true

module RubyLsp
  module Zodra
    module DslDetector
      ZODRA_METHODS = %i[type enum union contract api scalar configure].freeze
      CROSS_REFERENCE_METHODS = %i[response reference resources resource].freeze
      CROSS_REFERENCE_KEYWORDS = %i[from of contract].freeze

      PRIMITIVES = {
        string: { zod: 'z.string()', ts: 'string', options: 'min, max, format, enum' },
        integer: { zod: 'z.number().int()', ts: 'number', options: 'min, max' },
        decimal: { zod: 'z.number()', ts: 'number', options: 'min, max' },
        boolean: { zod: 'z.boolean()', ts: 'boolean', options: 'default' },
        datetime: { zod: 'z.iso.datetime()', ts: 'string', options: nil },
        date: { zod: 'z.iso.date()', ts: 'string', options: nil },
        uuid: { zod: 'z.uuid()', ts: 'string', options: nil },
        binary: { zod: 'z.string()', ts: 'string', options: nil },
        number: { zod: 'z.number()', ts: 'number', options: 'min, max' }
      }.freeze

      def zodra_call?(node)
        return false unless node.is_a?(Prism::CallNode)

        receiver = node.receiver
        return false unless receiver.is_a?(Prism::ConstantReadNode)
        return false unless receiver.name == :Zodra

        ZODRA_METHODS.include?(node.name)
      end

      def zodra_method(node)
        node.name
      end

      def extract_symbol_name(node)
        arguments = node.arguments&.arguments
        return unless arguments

        first_arg = arguments.first
        return unless first_arg.is_a?(Prism::SymbolNode)

        first_arg.value&.to_sym
      end

      def extract_string_name(node)
        arguments = node.arguments&.arguments
        return unless arguments

        first_arg = arguments.first
        return unless first_arg.is_a?(Prism::StringNode)

        first_arg.unescaped
      end

      def cross_reference_call?(node)
        return false unless node.is_a?(Prism::CallNode)

        CROSS_REFERENCE_METHODS.include?(node.name)
      end

      def keyword_argument_reference?(node)
        return false unless node.is_a?(Prism::CallNode)

        keyword_hash = extract_keyword_hash(node)
        return false unless keyword_hash

        keyword_hash.elements.any? do |element|
          next false unless element.is_a?(Prism::AssocNode)

          key = element.key
          next false unless key.is_a?(Prism::SymbolNode)

          CROSS_REFERENCE_KEYWORDS.include?(key.value&.to_sym)
        end
      end

      def extract_keyword_arguments(node)
        result = {}
        keyword_hash = extract_keyword_hash(node)
        return result unless keyword_hash

        keyword_hash.elements.each do |element|
          next unless element.is_a?(Prism::AssocNode)

          key = element.key
          next unless key.is_a?(Prism::SymbolNode)

          result[key.value&.to_sym] = element.value
        end

        result
      end

      def primitive?(name)
        PRIMITIVES.key?(name) || PRIMITIVES.key?(name.to_s.delete_suffix('?').to_sym)
      end

      def pascal_case(name)
        name.to_s.split('_').map(&:capitalize).join
      end

      def file_name(name)
        name.to_s.tr('_', '-')
      end

      def index_entry_name(method, name)
        category = method.to_s.capitalize
        "Zodra::#{category}::#{pascal_case(name)}"
      end

      private

      def extract_keyword_hash(node)
        arguments = node.arguments&.arguments
        return unless arguments

        arguments.find { |arg| arg.is_a?(Prism::KeywordHashNode) }
      end
    end
  end
end
