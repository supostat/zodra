# frozen_string_literal: true

RSpec.describe 'Export pipeline', :acceptance do
  before do
    Zodra::TypeRegistry.global.clear!
    Zodra::ContractRegistry.global.clear!
    Zodra::ApiRegistry.global.clear!
  end

  describe 'TypeScript export' do
    it 'generates interface from type DSL' do
      Zodra.type :invoice do
        uuid :id
        string :number
        decimal :amount, min: 0
        boolean :paid, default: false
      end

      result = Zodra::Export.generate(:typescript)

      expect(result).to include('export interface Invoice {')
      expect(result).to include('id: string;')
      expect(result).to include('number: string;')
      expect(result).to include('amount: number;')
      expect(result).to include('paid: boolean;')
    end

    it 'generates enum type' do
      Zodra.enum :status, values: %i[draft sent paid overdue]

      result = Zodra::Export.generate(:typescript)

      expect(result).to include("export type Status = 'draft' | 'sent' | 'paid' | 'overdue';")
    end

    it 'generates discriminated union' do
      Zodra.union :payment_method, discriminator: :type do
        variant :card do
          string :last_four
        end
        variant :bank_transfer do
          string :account_number
        end
      end

      result = Zodra::Export.generate(:typescript)

      expect(result).to include('export type PaymentMethod =')
      expect(result).to include("type: 'card'")
      expect(result).to include('lastFour: string')
      expect(result).to include("type: 'bank_transfer'")
      expect(result).to include('accountNumber: string')
    end

    it 'resolves references between types' do
      Zodra.type :customer do
        uuid :id
        string :name
      end

      Zodra.type :invoice do
        uuid :id
        reference :customer
        array :items, of: :item
      end

      Zodra.type :item do
        uuid :id
        string :description
        decimal :amount
      end

      result = Zodra::Export.generate(:typescript)

      expect(result).to include('export interface Customer {')
      expect(result).to include('export interface Invoice {')
      expect(result).to include('customer: Customer;')
      expect(result).to include('items: Item[];')
    end

    it 'handles optional and nullable fields' do
      Zodra.type :profile do
        string :name
        string? :nickname
        string :bio, nullable: true
      end

      result = Zodra::Export.generate(:typescript)

      expect(result).to include('name: string;')
      expect(result).to include('nickname?: string;')
      expect(result).to include('bio: null | string;')
    end
  end

  describe 'Zod export' do
    it 'generates schema from type DSL' do
      Zodra.type :invoice do
        uuid :id
        string :number
        decimal :amount, min: 0
        boolean :paid, default: false
      end

      result = Zodra::Export.generate(:zod)

      expect(result).to include('export const InvoiceSchema = z.object({')
      expect(result).to include('id: z.uuid()')
      expect(result).to include('number: z.string()')
      expect(result).to include('amount: z.number().min(0)')
      expect(result).to include('paid: z.boolean().default(false)')
    end

    it 'generates enum schema' do
      Zodra.enum :status, values: %i[draft sent paid overdue]

      result = Zodra::Export.generate(:zod)

      expect(result).to include("export const StatusSchema = z.enum(['draft', 'sent', 'paid', 'overdue']);")
    end

    it 'generates discriminated union schema' do
      Zodra.union :payment_method, discriminator: :type do
        variant :card do
          string :last_four
        end
        variant :bank_transfer do
          string :account_number
        end
      end

      result = Zodra::Export.generate(:zod)

      expect(result).to include("export const PaymentMethodSchema = z.discriminatedUnion('type',")
      expect(result).to include("z.literal('card')")
      expect(result).to include("z.literal('bank_transfer')")
    end
  end

  describe 'zod_import' do
    it 'uses custom import path' do
      Zodra.type :invoice do
        string :number
      end

      result = Zodra::Export.generate(:zod, zod_import: 'zod/v4')

      expect(result).to start_with("import { z } from 'zod/v4';")
    end

    it "defaults to 'zod'" do
      Zodra.type :invoice do
        string :number
      end

      result = Zodra::Export.generate(:zod)

      expect(result).to start_with("import { z } from 'zod';")
    end

    it 'ignores zod_import for typescript format' do
      Zodra.type :invoice do
        string :number
      end

      result = Zodra::Export.generate(:typescript, zod_import: 'zod/v4')

      expect(result).not_to include('import')
    end
  end

  describe 'key_format' do
    it 'transforms keys to camelCase' do
      Zodra.type :user_profile do
        string :first_name
        string :last_name
      end

      result = Zodra::Export.generate(:typescript, key_format: :camel)

      expect(result).to include('firstName: string;')
      expect(result).to include('lastName: string;')
    end
  end

  describe 'contract export' do
    before do
      Zodra.type :invoice do
        uuid :id
        string :number
        decimal :amount
      end

      contract = Zodra.contract :invoices do
        action :create do
          params do
            string :number, min: 1
            decimal :amount, min: 0
          end
          response :invoice
        end

        action :show do
          params do
            uuid :id
          end
          response :invoice
        end
      end

      contract.find_action(:create).tap do |a|
        a.http_method = :post
        a.path = '/invoices'
      end
      contract.find_action(:show).tap do |a|
        a.http_method = :get
        a.path = '/invoices/:id'
      end
    end

    it 'exports contract params as Zod schemas' do
      result = Zodra::Export.generate(:zod)

      expect(result).to include('export const CreateInvoicesParamsSchema = z.object({')
      expect(result).to include('number: z.string().min(1)')
      expect(result).to include('amount: z.number().min(0)')
      expect(result).to include('export const ShowInvoicesParamsSchema = z.object({')
      expect(result).to include('id: z.uuid()')
    end

    it 'exports contract descriptor as Zod' do
      result = Zodra::Export.generate(:zod)

      expect(result).to include('export const InvoicesContract = {')
      expect(result).to include("create: { method: 'POST' as const, path: '/invoices' as const, params: CreateInvoicesParamsSchema, response: InvoiceSchema }")
      expect(result).to include("show: { method: 'GET' as const, path: '/invoices/:id' as const, params: ShowInvoicesParamsSchema, response: InvoiceSchema }")
    end

    it 'exports contract params as TypeScript interfaces' do
      result = Zodra::Export.generate(:typescript)

      expect(result).to include('export interface CreateInvoicesParams {')
      expect(result).to include('number: string;')
      expect(result).to include('export interface ShowInvoicesParams {')
      expect(result).to include('id: string;')
    end

    it 'exports contract descriptor as TypeScript interface' do
      result = Zodra::Export.generate(:typescript)

      expect(result).to include('export interface InvoicesContract {')
      expect(result).to include("create: { method: 'POST'; path: '/invoices'; params: CreateInvoicesParams; response: Invoice }")
      expect(result).to include("show: { method: 'GET'; path: '/invoices/:id'; params: ShowInvoicesParams; response: Invoice }")
    end

    it 'handles action without response in descriptor' do
      contract = Zodra.contract :search do
        action :query do
          params do
            string :q, min: 1
          end
        end
      end

      contract.find_action(:query).tap do |a|
        a.http_method = :get
        a.path = '/search'
      end

      result = Zodra::Export.generate(:zod)

      expect(result).to include('export const QuerySearchParamsSchema = z.object({')
      expect(result).to include("query: { method: 'GET' as const, path: '/search' as const, params: QuerySearchParamsSchema }")
      expect(result).not_to include("query: { method: 'GET' as const, path: '/search' as const, params: QuerySearchParamsSchema, response:")
    end

    it 'handles empty contract' do
      Zodra.contract :empty_resource

      result = Zodra::Export.generate(:zod)

      expect(result).to include('export const EmptyResourceContract = {} as const;')
    end
  end

  describe 'topological sorting' do
    it 'orders Zod schemas so dependencies come first' do
      Zodra.type(:invoice) do
        uuid :id
        reference :customer
        array :items, of: :item
      end

      Zodra.type(:customer) do
        uuid :id
        string :name
      end

      Zodra.type(:item) do
        uuid :id
        string :description
      end

      result = Zodra::Export.generate(:zod)

      customer_pos = result.index('CustomerSchema')
      item_pos = result.index('ItemSchema')
      invoice_pos = result.index('InvoiceSchema = z.object')

      expect(customer_pos).to be < invoice_pos
      expect(item_pos).to be < invoice_pos
    end

    it 'orders TypeScript interfaces with dependencies first' do
      Zodra.type(:invoice) { reference :customer }
      Zodra.type(:customer) { string :name }

      result = Zodra::Export.generate(:typescript)

      customer_pos = result.index('export interface Customer')
      invoice_pos = result.index('export interface Invoice')

      expect(customer_pos).to be < invoice_pos
    end
  end

  describe 'surface resolver filtering' do
    it 'excludes types not reachable from contracts' do
      Zodra.type(:invoice) { string :number }
      Zodra.type(:unused_type) { string :data }

      Zodra.contract :invoices do
        action :show do
          params { uuid :id }
          response :invoice
        end
      end

      result = Zodra::Export.generate(:typescript)

      expect(result).to include('export interface Invoice')
      expect(result).not_to include('UnusedType')
    end

    it 'includes transitively referenced types' do
      Zodra.type(:address) { string :city }
      Zodra.type(:customer) do
        string :name
        reference :address
      end
      Zodra.type(:invoice) { reference :customer }
      Zodra.type(:unused) { string :data }

      Zodra.contract :invoices do
        action :show do
          params { uuid :id }
          response :invoice
        end
      end

      result = Zodra::Export.generate(:zod)

      expect(result).to include('AddressSchema')
      expect(result).to include('CustomerSchema')
      expect(result).to include('InvoiceSchema')
      expect(result).not_to include('UnusedSchema')
    end

    it 'exports all types when no contracts exist' do
      Zodra.type(:alpha) { string :name }
      Zodra.type(:beta) { string :name }

      result = Zodra::Export.generate(:typescript)

      expect(result).to include('export interface Alpha')
      expect(result).to include('export interface Beta')
    end
  end

  describe 'cyclic types' do
    it 'wraps self-referencing Zod type with z.lazy' do
      Zodra.type :comment do
        uuid :id
        string :text
        array :replies, of: :comment
      end

      result = Zodra::Export.generate(:zod, key_format: :keep)

      expect(result).to include('z.lazy(() => z.object(')
      expect(result).to include('z.ZodType<Comment>')
      expect(result).to include('replies: z.array(CommentSchema)')
    end

    it 'generates normal TypeScript interface for self-referencing type' do
      Zodra.type :comment do
        uuid :id
        string :text
        array :replies, of: :comment
      end

      result = Zodra::Export.generate(:typescript, key_format: :keep)

      expect(result).to include('export interface Comment {')
      expect(result).to include('replies: Comment[];')
      expect(result).not_to include('lazy')
    end

    it 'wraps mutually recursive Zod types with z.lazy' do
      Zodra.type :employee do
        string :name
        reference :department
      end
      Zodra.type :department do
        string :title
        reference :employee
      end

      result = Zodra::Export.generate(:zod, key_format: :keep)

      expect(result).to include('z.ZodType<Employee>')
      expect(result).to include('z.ZodType<Department>')
    end
  end

  describe 'end-to-end: API definition resolves routes into contract export' do
    before do
      Zodra.type :product do
        uuid :id
        string :name
        decimal :price
      end

      Zodra.contract :products do
        action :index do
          response :product, collection: true
        end

        action :show do
          params { uuid :id }
          response :product
        end

        action :create do
          params do
            string :name, min: 1
            decimal :price, min: 0
          end
          response :product
        end
      end

      Zodra.api '/api/v1' do
        resources :products, only: %i[index show create]
      end

      Zodra.resolve_routes!
    end

    it 'populates method and path from API resource definitions' do
      result = Zodra::Export.generate(:zod)

      expect(result).to include("method: 'GET' as const, path: '/products' as const, params: IndexProductsParamsSchema")
      expect(result).to include("method: 'GET' as const, path: '/products/:id' as const, params: ShowProductsParamsSchema")
      expect(result).to include("method: 'POST' as const, path: '/products' as const, params: CreateProductsParamsSchema")
    end

    it 'generates contracts barrel with baseUrl' do
      result = Zodra::Export.generate_contracts

      expect(result).to include("import { ProductsContract } from './schemas';")
      expect(result).to include('products: ProductsContract')
      expect(result).to include("export const baseUrl = '/api/v1';")
    end

    it 'generates TypeScript contract descriptor with resolved routes' do
      result = Zodra::Export.generate(:typescript)

      expect(result).to include("method: 'GET'; path: '/products'")
      expect(result).to include("method: 'POST'; path: '/products'")
      expect(result).to include("method: 'GET'; path: '/products/:id'")
    end
  end
end
