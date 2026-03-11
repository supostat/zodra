# frozen_string_literal: true

module Zodra
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("tasks/zodra.rake", __dir__)
    end

    initializer "zodra.route_helper" do
      ActionDispatch::Routing::Mapper.include(Zodra::RouteHelper)
    end
  end
end
