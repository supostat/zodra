# frozen_string_literal: true

module Zodra
  module RouteHelper
    def zodra_routes
      Zodra::Router.draw(self)
    end
  end
end
