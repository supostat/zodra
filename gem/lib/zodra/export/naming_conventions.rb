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

      def strip_base_path(path, base_path)
        return path unless base_path

        path.delete_prefix(base_path)
      end
    end
  end
end
