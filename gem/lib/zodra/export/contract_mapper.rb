# frozen_string_literal: true

module Zodra
  module Export
    class ContractMapper
      def initialize(api_definitions, contracts)
        @api_definitions = api_definitions
        @contracts = contracts
      end

      def generate
        return '' if @contracts.empty?

        parts = []
        parts << build_import
        parts << build_contracts_map
        parts << build_base_url if @api_definitions.any?
        parts.join("\n\n")
      end

      private

      def build_import
        schema_names = contract_names.map { |name| "#{pascal_case(name)}Contract" }
        "import { #{schema_names.join(', ')} } from './schemas';"
      end

      def build_contracts_map
        entries = contract_names.map do |name|
          "  #{camel_case(name)}: #{pascal_case(name)}Contract"
        end

        "export const contracts = {\n#{entries.join(",\n")},\n} as const;"
      end

      def build_base_url
        base_path = @api_definitions.first.base_path
        "export const baseUrl = '#{base_path}';"
      end

      def contract_names
        @contract_names ||= resolve_contract_names
      end

      def resolve_contract_names
        if @api_definitions.any?
          collect_resource_names(@api_definitions)
        else
          @contracts.map(&:name).map(&:to_s)
        end
      end

      def collect_resource_names(api_definitions)
        names = []
        api_definitions.each do |api|
          api.resources.each { |resource| collect_names_recursive(resource, names) }
        end
        names
      end

      def collect_names_recursive(resource, names)
        names << resource.contract_name.to_s
        resource.children.each { |child| collect_names_recursive(child, names) }
      end

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
