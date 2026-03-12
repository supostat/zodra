# frozen_string_literal: true

module Api
  module V1
    class SettingsController < ApplicationController
      include Zodra::Controller

      def show
        zodra_respond(Setting.instance)
      end

      def update
        setting = Setting.instance
        setting.update!(zodra_params)
        zodra_respond(setting)
      end
    end
  end
end
