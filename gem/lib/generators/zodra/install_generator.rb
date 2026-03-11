# frozen_string_literal: true

require 'rails/generators'

module Zodra
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    desc 'Creates a Zodra initializer and types directory'

    def create_initializer
      template 'initializer.rb.tt', 'config/initializers/zodra.rb'
    end

    def create_types_directory
      empty_directory 'app/types'
      create_file 'app/types/.keep'
    end
  end
end
