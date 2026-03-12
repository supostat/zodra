# frozen_string_literal: true

require 'ruby_lsp/addon'

require_relative 'dsl_detector'
require_relative 'indexing_enhancement'
require_relative 'hover_listener'
require_relative 'completion_listener'
require_relative 'definition_listener'
require_relative 'code_lens_listener'

module RubyLsp
  module Zodra
    class Addon < ::RubyLsp::Addon
      def activate(global_state, outgoing_queue)
        @global_state = global_state
        @outgoing_queue = outgoing_queue
      end

      def deactivate; end

      def name
        'Zodra'
      end

      def version
        '0.1.0'
      end

      def create_hover_listener(response_builder, node_context, dispatcher)
        return unless @global_state

        HoverListener.new(response_builder, node_context, @global_state, dispatcher)
      end

      def create_completion_listener(response_builder, node_context, dispatcher, _uri)
        return unless @global_state

        CompletionListener.new(response_builder, node_context, @global_state, dispatcher)
      end

      def create_definition_listener(response_builder, uri, node_context, dispatcher)
        return unless @global_state

        DefinitionListener.new(response_builder, uri, node_context, @global_state, dispatcher)
      end

      def create_code_lens_listener(response_builder, uri, dispatcher)
        CodeLensListener.new(response_builder, uri, dispatcher)
      end
    end
  end
end
