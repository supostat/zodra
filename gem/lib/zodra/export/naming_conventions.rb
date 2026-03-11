# frozen_string_literal: true

module Zodra
  module Export
    module NamingConventions
      private

      def pascal_case(name)
        name.to_s.split('_').map(&:capitalize).join
      end

      def camel_case(name)
        parts = name.to_s.split('_')
        parts.first + parts[1..].map(&:capitalize).join
      end
    end
  end
end
