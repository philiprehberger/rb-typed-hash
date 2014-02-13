# frozen_string_literal: true

module Philiprehberger
  module TypedHash
    # A typed hash instance with validation and coercion
    class Instance
      # @param schema [Schema] the schema definition
      # @param data [Hash] the input data
      def initialize(schema, data)
        @schema = schema
        @data = {}
        @errors = []

        process(data)
      end

      # Access a value by key
      #
      # @param key [Symbol] the key
      # @return [Object, nil] the value
      def [](key)
        @data[key]
      end

      # Check if the instance is valid
      #
      # @return [Boolean] true if no validation errors
      def valid?
        @errors.empty?
      end

      # Return validation errors
      #
      # @return [Array<String>] the error messages
      def errors
        @errors.dup
      end

      # Convert to a plain hash
      #
      # @return [Hash] the data as a hash
      def to_h
        @data.dup
      end

      # Merge with another hash or Instance, returning a new Instance
      #
      # @param other [Hash, Instance] the data to merge
      # @return [Instance] a new typed hash instance
      def merge(other)
        other_data = other.is_a?(Instance) ? other.to_h : other
        @schema.new(@data.merge(other_data))
      end

      private

      # Process input data against the schema
      #
      # @param data [Hash] the input data
      def process(data)
        symbolized = symbolize_keys(data)

        check_strict(symbolized) if @schema.strict

        @schema.fields.each do |name, field|
          if symbolized.key?(name)
            value = symbolized[name]
            value = apply_coercion(name, value, field[:coerce]) if field[:coerce]
            validate_type(name, value, field[:type])
            @data[name] = value
          elsif !field[:default].nil?
            @data[name] = field[:default]
          elsif !field[:optional]
            @errors << "#{name} is required"
          end
        end
      end

      # Symbolize hash keys
      #
      # @param hash [Hash] the input hash
      # @return [Hash] hash with symbol keys
      def symbolize_keys(hash)
        hash.each_with_object({}) do |(k, v), result|
          result[k.to_sym] = v
        end
      end

      # Check for unknown keys in strict mode
      #
      # @param data [Hash] the input data
      def check_strict(data)
        unknown = data.keys - @schema.fields.keys
        unknown.each do |key|
          @errors << "unknown key: #{key}"
        end
      end

      # Apply coercion to a value
      #
      # @param name [Symbol] the field name
      # @param value [Object] the value to coerce
      # @param coerce [Proc] the coercion function
      # @return [Object] the coerced value
      def apply_coercion(name, value, coerce)
        coerce.call(value)
      rescue StandardError => e
        @errors << "#{name} coercion failed: #{e.message}"
        value
      end

      # Validate a value against its expected type
      #
      # @param name [Symbol] the field name
      # @param value [Object] the value to validate
      # @param type [Class] the expected type
      def validate_type(name, value, type)
        return if value.is_a?(type)

        @errors << "#{name} must be a #{type}, got #{value.class}"
      end
    end
  end
end
