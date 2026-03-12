# frozen_string_literal: true

require 'fileutils'

module Zodra
  module Export
    class Writer
      def initialize(configuration)
        @configuration = configuration
      end

      def write_all
        file_tree = FileTreeBuilder.new(@configuration).build
        output_path = @configuration.output_path

        FileUtils.rm_rf(output_path)

        file_tree.each do |relative_path, content|
          full_path = File.join(output_path, relative_path)
          FileUtils.mkdir_p(File.dirname(full_path))
          File.write(full_path, content)
        end

        file_tree.keys.map { |relative_path| File.join(output_path, relative_path) }
      end
    end
  end
end
