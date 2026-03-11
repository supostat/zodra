# frozen_string_literal: true

RSpec.describe "API routing", :acceptance do
  before do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
    Zodra::ApiRegistry.global.clear!
  end

  it "defines API with resources via DSL" do
    api = Zodra.api "/api/v1" do
      resources :invoices
      resources :customers
    end

    expect(api.base_path).to eq("/api/v1")
    expect(api.resources.size).to eq(2)
    expect(api.resources.map(&:name)).to eq(%i[invoices customers])
  end

  it "defines singular resource" do
    api = Zodra.api "/api/v1" do
      resource :profile
    end

    profile = api.resources.first
    expect(profile.singular?).to be true
    expect(profile.crud_actions).not_to include(:index)
  end

  it "defines resources with only/except" do
    api = Zodra.api "/api/v1" do
      resources :invoices, only: %i[index show]
      resources :customers, except: %i[destroy]
    end

    invoices = api.resources[0]
    customers = api.resources[1]

    expect(invoices.crud_actions).to eq(%i[index show])
    expect(customers.crud_actions).to eq(%i[index show create update])
  end

  it "defines resources with custom member and collection actions" do
    api = Zodra.api "/api/v1" do
      resources :invoices do
        member do
          patch :void
          patch :send_invoice
        end
        collection do
          get :search
        end
      end
    end

    resource = api.resources.first
    member_actions = resource.custom_actions.select { |a| a[:member] }
    collection_actions = resource.custom_actions.reject { |a| a[:member] }

    expect(member_actions.map { |a| a[:name] }).to eq(%i[void send_invoice])
    expect(collection_actions.map { |a| a[:name] }).to eq([:search])
  end

  it "defines nested resources" do
    api = Zodra.api "/api/v1" do
      resources :invoices do
        resources :items
      end
    end

    invoices = api.resources.first
    expect(invoices.children.size).to eq(1)
    expect(invoices.children.first.name).to eq(:items)
  end

  it "uses explicit contract name" do
    api = Zodra.api "/api/v1" do
      resources :invoices, contract: :billing_invoices
    end

    expect(api.resources.first.contract_name).to eq(:billing_invoices)
  end

  it "resolves action routes from API + contract" do
    Zodra.contract :invoices do
      action :index do
        response(collection: true) do
          string :number
        end
      end

      action :create do
        params do
          string :number
          decimal :amount
        end
        response do
          string :number
        end
      end

      action :show do
        params { uuid :id }
        response do
          string :number
        end
      end

      action :void do
        params { uuid :id }
      end

      action :search do
        params { string :q }
      end
    end

    Zodra.api "/api/v1" do
      resources :invoices do
        member { patch :void }
        collection { get :search }
      end
    end

    router = Zodra::Router.new
    router.send(:resolve_action_routes!)

    contract = Zodra::ContractRegistry.global.find!(:invoices)

    index = contract.find_action(:index)
    expect(index.http_method).to eq(:get)
    expect(index.path).to eq("/api/v1/invoices")

    create = contract.find_action(:create)
    expect(create.http_method).to eq(:post)
    expect(create.path).to eq("/api/v1/invoices")

    show = contract.find_action(:show)
    expect(show.http_method).to eq(:get)
    expect(show.path).to eq("/api/v1/invoices/:id")

    void = contract.find_action(:void)
    expect(void.http_method).to eq(:patch)
    expect(void.path).to eq("/api/v1/invoices/:id/void")

    search = contract.find_action(:search)
    expect(search.http_method).to eq(:get)
    expect(search.path).to eq("/api/v1/invoices/search")
  end

  it "resolves nested resource action routes" do
    Zodra.contract :items do
      action :index do
        response(collection: true) do
          string :description
        end
      end

      action :create do
        params { string :description }
      end
    end

    Zodra.api "/api/v1" do
      resources :invoices do
        resources :items
      end
    end

    router = Zodra::Router.new
    router.send(:resolve_action_routes!)

    contract = Zodra::ContractRegistry.global.find!(:items)

    index = contract.find_action(:index)
    expect(index.http_method).to eq(:get)
    expect(index.path).to eq("/api/v1/invoices/:invoice_id/items")

    create = contract.find_action(:create)
    expect(create.http_method).to eq(:post)
    expect(create.path).to eq("/api/v1/invoices/:invoice_id/items")
  end
end
