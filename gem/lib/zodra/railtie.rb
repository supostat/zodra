# frozen_string_literal: true

module Zodra
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("tasks/zodra.rake", __dir__)
    end

    initializer "zodra.autoload_types" do |app|
      types_path = app.root.join("app", "types")
      app.autoloaders.main.push_dir(types_path) if types_path.exist?
    end
  end
end
