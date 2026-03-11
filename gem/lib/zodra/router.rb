# frozen_string_literal: true

module Zodra
  class Router
    def self.draw(context)
      new.draw(context)
    end

    def draw(context)
      load_zodra_definitions!
      resolve_action_routes!

      ApiRegistry.global.each do |api_definition|
        draw_api(context, api_definition)
      end
    end

    private

    def load_zodra_definitions!
      return unless defined?(Rails)

      TypeRegistry.global.clear!
      ContractRegistry.global.clear!
      ApiRegistry.global.clear!

      load_dir(Rails.root.join("app/types"))
      load_dir(Rails.root.join("app/contracts"))
      load_dir(Rails.root.join("config/apis"))
    end

    def load_dir(path)
      Dir[path.join("**/*.rb")].sort.each { |file| load(file) }
    end

    def resolve_action_routes!
      ApiRegistry.global.each do |api_definition|
        api_definition.resources.each do |resource|
          resolve_resource_actions(resource, api_definition.base_path)
        end
      end
    end

    def resolve_resource_actions(resource, base_path, parent_param: nil)
      segment = resource.name.to_s
      resource_path = parent_param ? "#{base_path}/#{parent_param}/#{segment}" : "#{base_path}/#{segment}"

      contract = ContractRegistry.global.find(resource.contract_name)

      if contract
        resource.crud_actions.each do |action_name|
          action = contract.find_action(action_name)
          next unless action

          crud = Resource::CRUD_ACTIONS[action_name]
          action.http_method = crud[:http_method]
          action.path = crud[:member] ? "#{resource_path}/:id" : resource_path
        end

        resource.custom_actions.each do |custom|
          action = contract.find_action(custom[:name])
          next unless action

          action.http_method = custom[:http_method]
          if custom[:member]
            action.path = "#{resource_path}/:id/#{custom[:name]}"
          else
            action.path = "#{resource_path}/#{custom[:name]}"
          end
        end
      end

      resource.children.each do |child|
        child_parent_param = resource.singular? ? nil : ":#{resource.name.to_s.singularize}_id"
        resolve_resource_actions(child, resource_path, parent_param: child_parent_param)
      end
    end

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
