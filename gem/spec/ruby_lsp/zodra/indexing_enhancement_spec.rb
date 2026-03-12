# frozen_string_literal: true

require 'prism'
require 'ruby_lsp/addon'
require 'ruby_indexer/ruby_indexer'
require_relative '../../../lib/ruby_lsp/zodra/indexing_enhancement'

RSpec.describe RubyLsp::Zodra::IndexingEnhancement do
  def index_source(source, uri: 'file:///test.rb')
    index = RubyIndexer::Index.new
    parsed_uri = URI(uri)
    parse_result = Prism.parse(source)
    dispatcher = Prism::Dispatcher.new

    RubyIndexer::DeclarationListener.new(
      index,
      dispatcher,
      parse_result,
      parsed_uri
    )

    dispatcher.dispatch(parse_result.value)
    index
  end

  it 'indexes Zodra.type as a class entry' do
    index = index_source('Zodra.type :product do; end')
    entries = index['Zodra::Type::Product']
    expect(entries).not_to be_nil
    expect(entries).not_to be_empty
  end

  it 'indexes Zodra.enum as a class entry' do
    index = index_source('Zodra.enum :order_status, values: %w[pending shipped]')
    entries = index['Zodra::Enum::OrderStatus']
    expect(entries).not_to be_nil
    expect(entries).not_to be_empty
  end

  it 'indexes Zodra.union as a class entry' do
    index = index_source('Zodra.union :payment_method, discriminator: :type do; end')
    entries = index['Zodra::Union::PaymentMethod']
    expect(entries).not_to be_nil
    expect(entries).not_to be_empty
  end

  it 'indexes Zodra.contract as a class entry' do
    index = index_source('Zodra.contract :products do; end')
    entries = index['Zodra::Contract::Products']
    expect(entries).not_to be_nil
    expect(entries).not_to be_empty
  end

  it 'indexes Zodra.scalar as a class entry' do
    index = index_source('Zodra.scalar :money, base: :string do |v|; end')
    entries = index['Zodra::Scalar::Money']
    expect(entries).not_to be_nil
    expect(entries).not_to be_empty
  end

  it 'does not index Zodra.api (routing, not a type)' do
    index = index_source('Zodra.api "/api/v1" do; end')
    entries = index.prefix_search('Zodra::Api')
    expect(entries.flatten).to be_empty
  end

  it 'does not index Zodra.configure' do
    index = index_source('Zodra.configure do; end')
    # configure has no name argument, so nothing should be indexed
    entries = index.prefix_search('Zodra::Configure')
    expect(entries.flatten).to be_empty
  end

  it 'does not index non-Zodra calls' do
    index = index_source('Other.type :product do; end')
    entries = index['Zodra::Type::Product']
    expect(entries).to be_nil
  end

  it 'indexes multiple definitions' do
    source = <<~RUBY
      Zodra.type :product do; end
      Zodra.type :customer do; end
      Zodra.enum :status, values: %w[active]
    RUBY

    index = index_source(source)
    expect(index['Zodra::Type::Product']).not_to be_nil
    expect(index['Zodra::Type::Customer']).not_to be_nil
    expect(index['Zodra::Enum::Status']).not_to be_nil
  end

  it 'stores correct file location' do
    index = index_source('Zodra.type :product do; end', uri: 'file:///app/types/product.rb')
    entries = index['Zodra::Type::Product']
    entry = entries.first
    expect(entry.uri.to_s).to eq('file:///app/types/product.rb')
    expect(entry.location.start_line).to eq(1)
  end
end
