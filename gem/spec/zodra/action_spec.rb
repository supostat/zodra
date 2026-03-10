# frozen_string_literal: true

RSpec.describe Zodra::Action do
  subject(:action) { described_class.new(name: :create) }

  it "has a name" do
    expect(action.name).to eq(:create)
  end

  it "initializes with empty params definition" do
    expect(action.params).to be_a(Zodra::Definition)
    expect(action.params.kind).to eq(:object)
    expect(action.params.attributes).to be_empty
  end

  it "allows setting http_method, path, and response" do
    action.http_method = :post
    action.path = "/invoices"
    action.response = :invoice

    expect(action.http_method).to eq(:post)
    expect(action.path).to eq("/invoices")
    expect(action.response).to eq(:invoice)
  end
end
