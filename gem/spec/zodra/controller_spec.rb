# frozen_string_literal: true

require 'spec_helper'
require 'active_support/concern'

RSpec.describe Zodra::Controller do
  let(:contract) do
    Zodra.contract(:invoices) do
      action :create do
        params do
          string :number, min: 1
          decimal :amount, min: 0
        end
      end

      action :index do
      end
    end
  end

  let(:rendered) { {} }

  let(:controller_class) do
    rendered_ref = rendered

    Class.new do
      @rescue_handlers = {}

      def self.rescue_from(*exceptions, &block)
        exceptions.each { |e| @rescue_handlers[e] = block }
      end

      class << self
        attr_reader :rescue_handlers
      end

      def self.wrap_parameters(*); end
      def self.name = 'InvoicesController'

      include Zodra::Controller

      zodra_contract :invoices

      attr_accessor :action_name

      define_method(:render) { |**kwargs| rendered_ref.merge!(kwargs) }

      def rescue_with_handler(exception)
        handler = self.class.rescue_handlers[exception.class]
        return false unless handler

        instance_exec(exception, &handler)
        true
      end
    end
  end

  let(:controller) do
    ctrl = controller_class.new
    ctrl.action_name = action_name
    ctrl
  end

  before do
    Zodra::ContractRegistry.global.clear!
    contract
  end

  after do
    Zodra::ContractRegistry.global.clear!
  end

  describe '#zodra_errors' do
    let(:action_name) { 'create' }

    context 'plain hash' do
      it 'renders 422 with field errors' do
        controller.send(:zodra_errors, { number: ['is already taken'] })

        expect(rendered[:status]).to eq(:unprocessable_entity)
        expect(rendered[:json]).to eq({ errors: { 'number' => ['is already taken'] } })
      end

      it 'renders multiple field errors' do
        controller.send(:zodra_errors, {
                          number: ['is already taken'],
                          amount: ['must be positive'],
                          base: ['insufficient balance']
                        })

        expect(rendered[:json][:errors]).to eq({
                                                 'number' => ['is already taken'],
                                                 'amount' => ['must be positive'],
                                                 'base' => ['insufficient balance']
                                               })
      end
    end

    context 'ActiveModel::Errors compatible' do
      it 'converts objects responding to #messages' do
        error_object = double('errors', messages: { number: ['taken'] })

        controller.send(:zodra_errors, error_object)

        expect(rendered[:json][:errors]).to eq({ 'number' => ['taken'] })
      end

      it 'converts objects responding to #to_hash' do
        error_object = double('errors', to_hash: { amount: ['negative'] })

        controller.send(:zodra_errors, error_object)

        expect(rendered[:json][:errors]).to eq({ 'amount' => ['negative'] })
      end
    end

    context 'custom status' do
      it 'allows overriding status' do
        controller.send(:zodra_errors, { base: ['conflict'] }, status: :conflict)

        expect(rendered[:status]).to eq(:conflict)
      end
    end

    context 'key transformation' do
      it 'transforms keys to camelCase by default' do
        Zodra.contract(:line_items) do
          action :create do
            params do
              string :first_name
              string :last_name
            end
          end
        end

        klass = controller_class
        klass.zodra_contract :line_items
        ctrl = klass.new
        ctrl.action_name = 'create'

        ctrl.send(:zodra_errors, { first_name: ['required'], last_name: ['required'] })

        expect(rendered[:json][:errors]).to eq({
                                                 'firstName' => ['required'],
                                                 'lastName' => ['required']
                                               })
      end

      it 'keeps keys when key_format is :keep' do
        original_format = Zodra.configuration.key_format
        Zodra.configuration.key_format = :keep

        controller.send(:zodra_errors, { number: ['taken'] })

        expect(rendered[:json][:errors]).to eq({ number: ['taken'] })
      ensure
        Zodra.configuration.key_format = original_format
      end
    end
  end

  describe 'error key validation' do
    let(:action_name) { 'create' }

    context 'in non-production environment' do
      before do
        stub_const('Rails', double('Rails', env: double('env', production?: false)))
      end

      it 'raises on unknown error keys' do
        expect do
          controller.send(:zodra_errors, { naem: ['required'] })
        end.to raise_error(Zodra::Error, /Unknown error keys \[:naem\].*Valid keys:.*:number.*:amount.*:base/)
      end

      it 'accepts valid param keys' do
        expect do
          controller.send(:zodra_errors, { number: ['taken'], amount: ['negative'] })
        end.not_to raise_error
      end

      it 'accepts :base key' do
        expect do
          controller.send(:zodra_errors, { base: ['something went wrong'] })
        end.not_to raise_error
      end

      it 'reports all unknown keys' do
        expect do
          controller.send(:zodra_errors, { foo: ['bad'], bar: ['worse'] })
        end.to raise_error(Zodra::Error, /\[:foo, :bar\]/)
      end
    end

    context 'in production environment' do
      before do
        stub_const('Rails', double('Rails', env: double('env', production?: true)))
      end

      it 'logs warning but still renders' do
        logger = double('Logger')
        allow(Zodra).to receive(:logger).and_return(logger)
        allow(logger).to receive(:warn)

        controller.send(:zodra_errors, { typo: ['error'] })

        expect(logger).to have_received(:warn).with(/Unknown error keys \[:typo\]/)
        expect(rendered[:json][:errors]).to have_key('typo')
      end
    end

    context 'action without params' do
      let(:action_name) { 'index' }

      it 'skips validation when no params defined' do
        expect do
          controller.send(:zodra_errors, { anything: ['ok'] })
        end.not_to raise_error
      end
    end
  end

  describe 'errors DSL (validation error keys)' do
    before do
      stub_const('Rails', double('Rails', env: double('env', production?: false)))
    end

    it 'validates against explicit error keys definition' do
      Zodra.contract(:periods) do
        action :create do
          params do
            string :date
            string :starts_at
          end

          errors do
            from_params
            key :base
          end
        end
      end

      klass = controller_class
      klass.zodra_contract :periods
      ctrl = klass.new
      ctrl.action_name = 'create'

      expect do
        ctrl.send(:zodra_errors, { date: ['err'], starts_at: ['err'], base: ['err'] })
      end.not_to raise_error

      expect do
        ctrl.send(:zodra_errors, { unknown: ['err'] })
      end.to raise_error(Zodra::Error, /Unknown error keys \[:unknown\]/)
    end

    it 'supports from_params except' do
      Zodra.contract(:filtered) do
        action :create do
          params do
            string :name
            string :internal_id
          end

          errors do
            from_params except: [:internal_id]
            key :base
          end
        end
      end

      klass = controller_class
      klass.zodra_contract :filtered
      ctrl = klass.new
      ctrl.action_name = 'create'

      expect do
        ctrl.send(:zodra_errors, { internal_id: ['err'] })
      end.to raise_error(Zodra::Error, /Unknown error keys \[:internal_id\]/)
    end

    it 'validates nested error keys in arrays' do
      Zodra.contract(:nested) do
        action :create do
          params do
            string :name
          end

          errors do
            key :name
            key :base
            key :items do
              key :starts_at
              key :ends_at
            end
          end
        end
      end

      klass = controller_class
      klass.zodra_contract :nested
      ctrl = klass.new
      ctrl.action_name = 'create'

      expect do
        ctrl.send(:zodra_errors, { items: [{ starts_at: ['err'], ends_at: ['err'] }] })
      end.not_to raise_error

      expect do
        ctrl.send(:zodra_errors, { items: [{ bad_key: ['err'] }] })
      end.to raise_error(Zodra::Error, /Unknown error keys \[:bad_key\] in items\[0\]/)
    end

    it 'falls back to params-derived keys when no errors block defined' do
      klass = controller_class
      klass.zodra_contract :invoices
      ctrl = klass.new
      ctrl.action_name = 'create'

      expect do
        ctrl.send(:zodra_errors, { number: ['err'], amount: ['err'], base: ['ok'] })
      end.not_to raise_error
    end
  end

  describe 'error DSL' do
    it 'stores error definitions on action' do
      Zodra.contract(:orders) do
        action :create do
          params do
            string :number
          end
          error :already_finalized, status: 409
          error :insufficient_balance, status: 422
        end
      end

      order_contract = Zodra::ContractRegistry.global.find!(:orders)
      action = order_contract.find_action(:create)

      expect(action.errors).to have_key(:already_finalized)
      expect(action.errors[:already_finalized]).to eq({ code: :already_finalized, status: 409 })
      expect(action.errors[:insufficient_balance]).to eq({ code: :insufficient_balance, status: 422 })
    end

    it 'find_error returns nil for unknown codes' do
      action = contract.find_action(:create)

      expect(action.find_error(:nonexistent)).to be_nil
    end
  end

  describe '.zodra_rescue' do
    let(:action_name) { 'create' }

    let(:contract) do
      Zodra.contract(:invoices) do
        action :create do
          params do
            string :number, min: 1
            decimal :amount, min: 0
          end
          error :already_finalized, status: 409
          error :insufficient_balance, status: 422
        end

        action :index do
        end
      end
    end

    let(:already_finalized_error) do
      Class.new(StandardError)
    end

    let(:insufficient_balance_error) do
      Class.new(StandardError)
    end

    it 'renders business error with code and message' do
      controller_class.zodra_rescue :create, already_finalized_error, as: :already_finalized

      exception = already_finalized_error.new('Invoice is already finalized')
      controller.rescue_with_handler(exception)

      expect(rendered[:status]).to eq(409)
      expect(rendered[:json]).to eq({
                                      error: { code: 'already_finalized', message: 'Invoice is already finalized' }
                                    })
    end

    it 'uses status from error definition in contract' do
      controller_class.zodra_rescue :create, insufficient_balance_error, as: :insufficient_balance

      exception = insufficient_balance_error.new('Not enough funds')
      controller.rescue_with_handler(exception)

      expect(rendered[:status]).to eq(422)
      expect(rendered[:json][:error][:code]).to eq('insufficient_balance')
    end

    it 're-raises if exception does not match current action' do
      controller_class.zodra_rescue :index, already_finalized_error, as: :already_finalized

      exception = already_finalized_error.new('wrong action')

      expect do
        controller.send(:handle_zodra_business_error, exception)
      end.to raise_error(already_finalized_error, 'wrong action')
    end

    it 'falls back to 500 if error code not in contract' do
      unmapped_error = Class.new(StandardError)
      controller_class.zodra_rescue :create, unmapped_error, as: :unknown_code

      exception = unmapped_error.new('something broke')
      controller.rescue_with_handler(exception)

      expect(rendered[:status]).to eq(:internal_server_error)
      expect(rendered[:json][:error][:code]).to eq('unknown_code')
    end

    it 'handles multiple error mappings for same action' do
      controller_class.zodra_rescue :create, already_finalized_error, as: :already_finalized
      controller_class.zodra_rescue :create, insufficient_balance_error, as: :insufficient_balance

      exception = insufficient_balance_error.new('No funds')
      controller.rescue_with_handler(exception)

      expect(rendered[:json][:error][:code]).to eq('insufficient_balance')
      expect(rendered[:status]).to eq(422)
    end
  end
end
