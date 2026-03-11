# frozen_string_literal: true

require 'generators/zodra/install_generator'

RSpec.describe Zodra::InstallGenerator do
  it 'has a source root with templates' do
    source_root = described_class.source_root
    expect(File.directory?(source_root)).to be true
  end

  it 'includes initializer template' do
    template_path = File.join(described_class.source_root, 'initializer.rb.tt')
    expect(File.exist?(template_path)).to be true
  end

  it 'initializer template contains configuration block' do
    template_path = File.join(described_class.source_root, 'initializer.rb.tt')
    content = File.read(template_path)

    expect(content).to include('Zodra.configure')
    expect(content).to include('config.output_path')
    expect(content).to include('config.key_format')
    expect(content).to include('config.zod_import')
  end
end
