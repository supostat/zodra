# frozen_string_literal: true

require "bigdecimal"
require "time"
require "date"

module Zodra
  module ParamsCoercer
    UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
    DECIMAL_PATTERN = /\A-?\d+(\.\d+)?\z/

    TRUE_VALUES = %w[true 1 yes].freeze
    FALSE_VALUES = %w[false 0 no].freeze

    def self.call(value, type, of: nil)
      case type
      when :string   then value.to_s
      when :integer  then coerce_integer(value)
      when :decimal  then coerce_decimal(value)
      when :number   then coerce_number(value)
      when :boolean  then coerce_boolean(value)
      when :datetime then coerce_datetime(value)
      when :date     then coerce_date(value)
      when :uuid     then coerce_uuid(value)
      when :binary   then value.to_s
      when :array    then coerce_array(value, of)
      else
        scalar = ScalarRegistry.global.find(type)
        scalar ? scalar.coercer.call(value) : value
      end
    end

    def self.coerce_integer(value)
      return value if value.is_a?(Integer)

      Integer(value)
    rescue ArgumentError, TypeError
      :coercion_error
    end

    def self.coerce_decimal(value)
      return value if value.is_a?(BigDecimal)

      string = value.to_s
      return :coercion_error unless DECIMAL_PATTERN.match?(string)

      BigDecimal(string)
    end

    def self.coerce_number(value)
      return value if value.is_a?(Float)

      Float(value)
    rescue ArgumentError, TypeError
      :coercion_error
    end

    def self.coerce_boolean(value)
      return value if value == true || value == false

      string = value.to_s.downcase
      return true if TRUE_VALUES.include?(string)
      return false if FALSE_VALUES.include?(string)

      :coercion_error
    end

    def self.coerce_datetime(value)
      return value if value.is_a?(Time)

      Time.parse(value.to_s)
    rescue ArgumentError
      :coercion_error
    end

    def self.coerce_date(value)
      return value if value.is_a?(Date) && !value.is_a?(DateTime)

      Date.parse(value.to_s)
    rescue ArgumentError, Date::Error
      :coercion_error
    end

    def self.coerce_uuid(value)
      string = value.to_s
      UUID_PATTERN.match?(string) ? string : :coercion_error
    end

    def self.coerce_array(value, element_type)
      return :coercion_error unless value.is_a?(Array)

      coerced = value.map { |element| call(element, element_type) }
      coerced.any? { |v| v == :coercion_error } ? :coercion_error : coerced
    end

    private_class_method :coerce_integer, :coerce_decimal, :coerce_number,
                         :coerce_boolean, :coerce_datetime, :coerce_date,
                         :coerce_uuid, :coerce_array
  end
end
