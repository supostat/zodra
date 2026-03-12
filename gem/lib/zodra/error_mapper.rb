# frozen_string_literal: true

module Zodra
  class ErrorMapper
    class UnmappedErrorsError < Zodra::Error; end

    def self.call(**)
      mapper = new
      mapper.call(**)
    end

    def call(**_kwargs)
      raise NotImplementedError, "#{self.class}#call must be implemented"
    end

    private

    def collect(record_or_errors, &)
      errors_hash = extract_errors(record_or_errors)
      source = Source.new(errors_hash)
      @current_source = source
      instance_eval(&)
      @current_source = nil
      (@sources ||= []) << source
    end

    def map(mapping)
      source = @current_source
      raise Zodra::Error, 'map must be called inside a collect block' unless source

      if mapping.is_a?(Hash)
        mapping.each do |from_key, to_key|
          transfer(source, from_key, to_key)
        end
      else
        transfer(source, mapping, mapping)
      end
    end

    def consume(key)
      source = @current_source
      raise Zodra::Error, 'consume must be called inside a collect block' unless source

      source.consume(key)
    end

    def source_errors
      raise Zodra::Error, 'source_errors must be called inside a collect block' unless @current_source

      @current_source.errors_hash
    end

    def add(key, message)
      sym_key = key.to_sym
      result[sym_key] ||= []
      result[sym_key] << message
    end

    def ignore(*keys)
      source = @current_source
      raise Zodra::Error, 'ignore must be called inside a collect block' unless source

      keys.each { |key| source.consume(key) }
    end

    def map_remaining
      source = @current_source
      raise Zodra::Error, 'map_remaining must be called inside a collect block' unless source

      source.unmapped.each_key { |key| transfer(source, key, key) }
    end

    def assert_no_unmapped!
      return unless @sources

      details = []
      @sources.each do |source|
        unmapped = source.unmapped
        next if unmapped.empty?

        details << unmapped.inspect
      end

      return if details.empty?

      raise UnmappedErrorsError, "Unmapped errors: #{details.join(', ')}"
    end

    def result
      @result ||= {}
    end

    def transfer(source, from_key, to_key)
      messages = source.consume(from_key)
      return unless messages

      result[to_key.to_sym] = result.key?(to_key.to_sym) ? result[to_key.to_sym] + messages : messages
    end

    def extract_errors(record_or_errors)
      case record_or_errors
      when Hash
        normalize_hash(record_or_errors)
      else
        raise ArgumentError, "Expected a Hash or an object responding to #errors, got #{record_or_errors.class}" unless record_or_errors.respond_to?(:errors)

        normalize_hash(record_or_errors.errors.to_hash)

      end
    end

    def normalize_hash(hash)
      hash.each_with_object({}) do |(key, value), result|
        result[key.to_s] = Array(value)
      end
    end

    class Source
      attr_reader :errors_hash

      def initialize(errors_hash)
        @errors_hash = errors_hash.freeze
        @consumed = Set.new
      end

      def consume(key)
        string_key = key.to_s
        return nil unless @errors_hash.key?(string_key)

        @consumed << string_key
        @errors_hash[string_key]
      end

      def unmapped
        @errors_hash.except(*@consumed)
      end
    end
  end
end
