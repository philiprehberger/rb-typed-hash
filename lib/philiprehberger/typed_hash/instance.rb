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
        @frozen = false

        process(data)
      end

      # Access a value by key
      #
      # @param key [Symbol] the key
      # @return [Object, nil] the value
      def [](key)
        @data[key]
      end

      # Set a value by key (raises if frozen)
      #
      # @param key [Symbol] the key
      # @param value [Object] the value
      def []=(key, value)
        raise Philiprehberger::TypedHash::FrozenError, 'cannot modify a frozen instance' if @frozen

        @data[key] = value
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
        @data.each_with_object({}) do |(k, v), result|
          result[k] = v.is_a?(Instance) ? v.to_h : v
        end
      end

      # Merge with another hash or Instance, returning a new Instance
      #
      # @param other [Hash, Instance] the data to merge
      # @return [Instance] a new typed hash instance
      def merge(other)
        other_data = other.is_a?(Instance) ? other.to_h : other
        @schema.new(to_h.merge(other_data))
      end

      # Return a new Instance with only the specified keys
      #
      # @param keys [Array<Symbol>] keys to keep
      # @return [Instance] a new typed hash instance
      def pick(*keys)
        picked = to_h.slice(*keys)
        @schema.new(picked)
      end

      # Return a new Instance without the specified keys
      #
      # @param keys [Array<Symbol>] keys to remove
      # @return [Instance] a new typed hash instance
      def omit(*keys)
        omitted = to_h.except(*keys)
        @schema.new(omitted)
      end

      # Serialize to JSON string
      #
      # @return [String] JSON representation
      def to_json(*_args)
        to_h.to_json
      end

      # Freeze the instance, making it immutable
      #
      # @return [self]
      def freeze
        @frozen = true
        self
      end

      # Check if the instance is frozen
      #
      # @return [Boolean]
      def frozen?
        @frozen
      end

      # Compute the diff between this instance and another
      #
      # @param other [Instance] the other instance to compare
      # @return [Hash] diff of changed keys as { key => { old:, new: } }
      def diff(other)
        all_keys = (to_h.keys | other.to_h.keys).uniq
        all_keys.each_with_object({}) do |key, result|
          old_val = self[key]
          new_val = other[key]
          result[key] = { old: old_val, new: new_val } unless old_val == new_val
        end
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

            if field[:nested_schema]
              process_nested(name, value, field[:nested_schema])
            else
              validate_type(name, value, field[:type])
              @data[name] = value
            end
          elsif !field[:default].nil?
            @data[name] = field[:default]
          elsif !field[:optional]
            @errors << "#{name} is required"
          end
        end
      end

      # Process a nested schema field
      #
      # @param name [Symbol] the field name
      # @param value [Object] the value (should be a Hash)
      # @param nested_schema [Schema] the nested schema
      def process_nested(name, value, nested_schema)
        unless value.is_a?(Hash)
          @errors << "#{name} must be a Hash, got #{value.class}"
          return
        end

        nested_instance = nested_schema.new(value)
        unless nested_instance.valid?
          nested_instance.errors.each do |err|
            @errors << "#{name}.#{err}"
          end
        end
        @data[name] = nested_instance
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
