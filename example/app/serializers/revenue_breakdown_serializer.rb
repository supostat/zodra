# frozen_string_literal: true

class RevenueBreakdownSerializer < Oj::Serializer
  object_as :object
  serializer_attributes :status, :total, :count

  def status = object.status
  def total  = object.total.to_f
  def count  = object.count.to_i
end
