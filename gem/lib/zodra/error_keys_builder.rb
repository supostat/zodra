# frozen_string_literal: true

module Zodra
  class ErrorKeysBuilder
    def initialize(definition, params_definition:)
      @definition = definition
      @params_definition = params_definition
    end

    def key(name, &block)
      if block
        children_definition = ErrorKeysDefinition.new
        ErrorKeysBuilder.new(children_definition, params_definition: nil).instance_eval(&block)
        @definition.add_key(name, children: children_definition.keys)
      else
        @definition.add_key(name)
      end
    end

    def from_params(except: [])
      raise Zodra::Error, 'from_params requires a params definition' unless @params_definition

      @definition.add_keys_from_params(@params_definition, except:)
    end
  end
end
