# frozen_string_literal: true

module Zodra
  class ApiBuilder
    def initialize(api_definition)
      @api_definition = api_definition
    end

    def resources(name, contract: nil, controller: nil, only: nil, except: nil, &block)
      resource = Resource.new(name:, singular: false, contract:, controller:, only:, except:)
      ResourceBuilder.new(resource).instance_eval(&block) if block
      @api_definition.add_resource(resource)
      resource
    end

    def resource(name, contract: nil, controller: nil, only: nil, except: nil, &block)
      resource = Resource.new(name:, singular: true, contract:, controller:, only:, except:)
      ResourceBuilder.new(resource).instance_eval(&block) if block
      @api_definition.add_resource(resource)
      resource
    end
  end
end
