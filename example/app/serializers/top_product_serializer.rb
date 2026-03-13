# frozen_string_literal: true

class TopProductSerializer < Oj::Serializer
  object_as :object
  serializer_attributes :name, :sku, :units_sold, :revenue

  def name       = object.name
  def sku        = object.sku
  def units_sold = object.units_sold.to_i
  def revenue    = object.revenue.to_f
end
