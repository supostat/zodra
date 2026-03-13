# frozen_string_literal: true

module SsrHelper
  SSR_TO_SPA_MAP = {
    "/ssr/dashboard" => "/dashboard",
    "/ssr/products" => "/products",
    "/ssr/orders" => "/orders",
    "/ssr/settings" => "/settings"
  }.freeze

  def spa_path_for(ssr_path)
    SSR_TO_SPA_MAP.each do |prefix, spa_prefix|
      return ssr_path.sub(prefix, spa_prefix) if ssr_path.start_with?(prefix)
    end
    "/"
  end
end
