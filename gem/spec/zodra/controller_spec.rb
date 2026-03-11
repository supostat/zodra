# frozen_string_literal: true

require "spec_helper"
require "active_support/concern"

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
      def self.rescue_from(*); end
      def self.wrap_parameters(*); end
      def self.name = "InvoicesController"

      include Zodra::Controller
      zodra_contract :invoices

      attr_accessor :action_name

      define_method(:render) { |**kwargs| rendered_ref.merge!(kwargs) }
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

  describe "#zodra_errors" do
    let(:action_name) { "create" }

    context "plain hash" do
      it "renders 422 with field errors" do
        controller.send(:zodra_errors, { number: ["is already taken"] })

        expect(rendered[:status]).to eq(:unprocessable_entity)
        expect(rendered[:json]).to eq({ errors: { "number" => ["is already taken"] } })
      end

      it "renders multiple field errors" do
        controller.send(:zodra_errors, {
          number: ["is already taken"],
          amount: ["must be positive"],
          base: ["insufficient balance"]
        })

        expect(rendered[:json][:errors]).to eq({
          "number" => ["is already taken"],
          "amount" => ["must be positive"],
          "base" => ["insufficient balance"]
        })
      end
    end

    context "ActiveModel::Errors compatible" do
      it "converts objects responding to #messages" do
        error_object = double("errors", messages: { number: ["taken"] })

        controller.send(:zodra_errors, error_object)

        expect(rendered[:json][:errors]).to eq({ "number" => ["taken"] })
      end

      it "converts objects responding to #to_hash" do
        error_object = double("errors", to_hash: { amount: ["negative"] })

        controller.send(:zodra_errors, error_object)

        expect(rendered[:json][:errors]).to eq({ "amount" => ["negative"] })
      end
    end

    context "custom status" do
      it "allows overriding status" do
        controller.send(:zodra_errors, { base: ["conflict"] }, status: :conflict)

        expect(rendered[:status]).to eq(:conflict)
      end
    end

    context "key transformation" do
      it "transforms keys to camelCase by default" do
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
        ctrl.action_name = "create"

        ctrl.send(:zodra_errors, { first_name: ["required"], last_name: ["required"] })

        expect(rendered[:json][:errors]).to eq({
          "firstName" => ["required"],
          "lastName" => ["required"]
        })
      end

      it "keeps keys when key_format is :keep" do
        original_format = Zodra.configuration.key_format
        Zodra.configuration.key_format = :keep

        controller.send(:zodra_errors, { number: ["taken"] })

        expect(rendered[:json][:errors]).to eq({ number: ["taken"] })
      ensure
        Zodra.configuration.key_format = original_format
      end
    end
  end

  describe "error key validation" do
    let(:action_name) { "create" }

    context "in non-production environment" do
      before do
        stub_const("Rails", double("Rails", env: double("env", production?: false)))
      end

      it "raises on unknown error keys" do
        expect {
          controller.send(:zodra_errors, { naem: ["required"] })
        }.to raise_error(Zodra::Error, /Unknown error keys \[:naem\].*Valid keys:.*:number.*:amount.*:base/)
      end

      it "accepts valid param keys" do
        expect {
          controller.send(:zodra_errors, { number: ["taken"], amount: ["negative"] })
        }.not_to raise_error
      end

      it "accepts :base key" do
        expect {
          controller.send(:zodra_errors, { base: ["something went wrong"] })
        }.not_to raise_error
      end

      it "reports all unknown keys" do
        expect {
          controller.send(:zodra_errors, { foo: ["bad"], bar: ["worse"] })
        }.to raise_error(Zodra::Error, /\[:foo, :bar\]/)
      end
    end

    context "in production environment" do
      before do
        stub_const("Rails", double("Rails", env: double("env", production?: true)))
      end

      it "logs warning but still renders" do
        logger = instance_double("Logger")
        allow(Zodra).to receive(:logger).and_return(logger)
        allow(logger).to receive(:warn)

        controller.send(:zodra_errors, { typo: ["error"] })

        expect(logger).to have_received(:warn).with(/Unknown error keys \[:typo\]/)
        expect(rendered[:json][:errors]).to have_key("typo")
      end
    end

    context "action without params" do
      let(:action_name) { "index" }

      it "skips validation when no params defined" do
        expect {
          controller.send(:zodra_errors, { anything: ["ok"] })
        }.not_to raise_error
      end
    end
  end
end
