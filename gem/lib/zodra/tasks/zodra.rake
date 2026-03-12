# frozen_string_literal: true

namespace :zodra do
  desc 'Export all type definitions (types + contracts)'
  task export: :environment do
    Zodra.load_definitions!
    writer = Zodra::Export::Writer.new(Zodra.configuration)
    paths = writer.write_all
    paths.each { |path| puts "Generated #{path}" }
  end
end
