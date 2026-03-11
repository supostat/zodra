# frozen_string_literal: true

module Zodra
  class Router
    def self.draw(context)
      new.draw(context)
    end

    def draw(context)
      Zodra.load_definitions!

      ApiRegistry.global.each do |api_definition|
        draw_api(context, api_definition)
      end
    end

    private

    def draw_api(context, api_definition)
      router = self
      top_resources = api_definition.resources

      context.scope module: api_definition.controller_namespace, path: api_definition.base_path do
        top_resources.each do |resource|
          router.send(:draw_resource, context, resource)
        end
      end
    end

    def draw_resource(context, resource)
      router = self
      resource_method = resource.singular? ? :resource : :resources

      options = { only: resource.crud_actions }
      options[:controller] = resource.controller_name if resource.controller_name

      member_actions = resource.custom_actions.select { |a| a[:member] }
      collection_actions = resource.custom_actions.reject { |a| a[:member] }
      children = resource.children

      context.send(resource_method, resource.name, **options) do
        member_actions.each do |custom|
          member { send(custom[:http_method], custom[:name]) }
        end

        collection_actions.each do |custom|
          collection { send(custom[:http_method], custom[:name]) }
        end

        children.each do |child|
          router.send(:draw_resource, self, child)
        end
      end
    end
  end
end
