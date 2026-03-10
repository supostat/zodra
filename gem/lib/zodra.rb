# frozen_string_literal: true

require "zeitwerk"

module Zodra
  class << self
    private

    def setup_autoload
      @loader = Zeitwerk::Loader.for_gem.tap do |loader|
        loader.inflector.inflect("dsl" => "DSL")
        loader.setup
      end
    end
  end

  setup_autoload
end
