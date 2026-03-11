# frozen_string_literal: true

module Zodra
  class ApiDefinition
    attr_reader :base_path, :resources

    def initialize(base_path:)
      @base_path = base_path
      @resources = []
    end

    def add_resource(resource)
      @resources << resource
    end

    def namespaces
      @base_path.split('/').reject(&:empty?).map(&:to_sym)
    end

    def controller_namespace
      namespaces.join('/')
    end
  end
end
