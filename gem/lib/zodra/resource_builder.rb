# frozen_string_literal: true

module Zodra
  class ResourceBuilder
    HTTP_METHODS = %i[get post put patch delete].freeze

    def initialize(resource)
      @resource = resource
    end

    def member(&block)
      MemberContext.new(@resource).instance_eval(&block)
    end

    def collection(&block)
      CollectionContext.new(@resource).instance_eval(&block)
    end

    def resources(name, contract: nil, controller: nil, only: nil, except: nil, &block)
      child = Resource.new(name:, singular: false, contract:, controller:, only:, except:)
      ResourceBuilder.new(child).instance_eval(&block) if block
      @resource.add_child(child)
      child
    end

    def resource(name, contract: nil, controller: nil, only: nil, except: nil, &block)
      child = Resource.new(name:, singular: true, contract:, controller:, only:, except:)
      ResourceBuilder.new(child).instance_eval(&block) if block
      @resource.add_child(child)
      child
    end

    class MemberContext
      HTTP_METHODS.each do |verb|
        define_method(verb) do |action_name|
          @resource.add_member_action(verb, action_name)
        end
      end

      def initialize(resource)
        @resource = resource
      end
    end

    class CollectionContext
      HTTP_METHODS.each do |verb|
        define_method(verb) do |action_name|
          @resource.add_collection_action(verb, action_name)
        end
      end

      def initialize(resource)
        @resource = resource
      end
    end
  end
end
