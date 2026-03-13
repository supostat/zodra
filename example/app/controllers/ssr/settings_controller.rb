# frozen_string_literal: true

module Ssr
  class SettingsController < BaseController
    def show
      @props = zodra_serialize_inline(Setting.instance, :settings, "show")
    end
  end
end
