# frozen_string_literal: true

require 'prism'
require_relative '../../../lib/ruby_lsp/zodra/dsl_detector'

RSpec.describe RubyLsp::Zodra::DslDetector do
  include described_class

  def parse_call(source)
    ast = Prism.parse(source).value
    ast.statements.body.first
  end

  describe '#zodra_call?' do
    it 'detects Zodra.type call' do
      node = parse_call('Zodra.type :product do; end')
      expect(zodra_call?(node)).to be true
    end

    it 'detects Zodra.enum call' do
      node = parse_call('Zodra.enum :status, values: %w[active inactive]')
      expect(zodra_call?(node)).to be true
    end

    it 'detects Zodra.union call' do
      node = parse_call('Zodra.union :payment, discriminator: :type do; end')
      expect(zodra_call?(node)).to be true
    end

    it 'detects Zodra.contract call' do
      node = parse_call('Zodra.contract :products do; end')
      expect(zodra_call?(node)).to be true
    end

    it 'detects Zodra.api call' do
      node = parse_call('Zodra.api "/api/v1" do; end')
      expect(zodra_call?(node)).to be true
    end

    it 'detects Zodra.scalar call' do
      node = parse_call('Zodra.scalar :money, base: :string do |v|; end')
      expect(zodra_call?(node)).to be true
    end

    it 'detects Zodra.configure call' do
      node = parse_call('Zodra.configure do; end')
      expect(zodra_call?(node)).to be true
    end

    it 'rejects non-Zodra receiver' do
      node = parse_call('Other.type :product')
      expect(zodra_call?(node)).to be false
    end

    it 'rejects unknown method on Zodra' do
      node = parse_call('Zodra.unknown :thing')
      expect(zodra_call?(node)).to be false
    end

    it 'rejects method without receiver' do
      node = parse_call('type :product')
      expect(zodra_call?(node)).to be false
    end
  end

  describe '#zodra_method' do
    it 'returns the method name' do
      node = parse_call('Zodra.type :product do; end')
      expect(zodra_method(node)).to eq(:type)
    end
  end

  describe '#extract_symbol_name' do
    it 'extracts symbol argument' do
      node = parse_call('Zodra.type :product do; end')
      expect(extract_symbol_name(node)).to eq(:product)
    end

    it 'returns nil for string argument' do
      node = parse_call('Zodra.api "/api/v1" do; end')
      expect(extract_symbol_name(node)).to be_nil
    end

    it 'returns nil for no arguments' do
      node = parse_call('Zodra.configure do; end')
      expect(extract_symbol_name(node)).to be_nil
    end
  end

  describe '#extract_string_name' do
    it 'extracts string argument' do
      node = parse_call('Zodra.api "/api/v1" do; end')
      expect(extract_string_name(node)).to eq('/api/v1')
    end

    it 'returns nil for symbol argument' do
      node = parse_call('Zodra.type :product do; end')
      expect(extract_string_name(node)).to be_nil
    end
  end

  describe '#cross_reference_call?' do
    it 'detects response call' do
      node = parse_call('response :product')
      expect(cross_reference_call?(node)).to be true
    end

    it 'detects reference call' do
      node = parse_call('reference :customer')
      expect(cross_reference_call?(node)).to be true
    end

    it 'detects resources call' do
      node = parse_call('resources :products')
      expect(cross_reference_call?(node)).to be true
    end

    it 'rejects non-cross-reference call' do
      node = parse_call('string :name')
      expect(cross_reference_call?(node)).to be false
    end
  end

  describe '#extract_keyword_arguments' do
    it 'extracts keyword arguments' do
      node = parse_call('Zodra.type :x, from: :product, pick: [:name]')
      kwargs = extract_keyword_arguments(node)
      expect(kwargs.keys).to contain_exactly(:from, :pick)
    end

    it 'returns empty hash when no keywords' do
      node = parse_call('Zodra.type :product')
      expect(extract_keyword_arguments(node)).to eq({})
    end
  end

  describe '#primitive?' do
    it 'recognizes string' do
      expect(primitive?(:string)).to be true
    end

    it 'recognizes optional variant' do
      expect(primitive?(:string?)).to be true
    end

    it 'rejects non-primitive' do
      expect(primitive?(:response)).to be false
    end
  end

  describe '#pascal_case' do
    it 'converts snake_case to PascalCase' do
      expect(pascal_case(:order_status)).to eq('OrderStatus')
    end

    it 'handles single word' do
      expect(pascal_case(:product)).to eq('Product')
    end
  end

  describe '#index_entry_name' do
    it 'builds full entry name' do
      expect(index_entry_name(:type, :product)).to eq('Zodra::Type::Product')
    end

    it 'handles snake_case names' do
      expect(index_entry_name(:enum, :order_status)).to eq('Zodra::Enum::OrderStatus')
    end
  end
end
