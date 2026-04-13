# frozen_string_literal: true

module Philiprehberger
  module TypedHash
    # Schema definition for a typed hash
    class Schema
      # @param strict [Boolean] when true, reject unknown keys
      def initialize(strict: false)
        @fields = {}
        @strict = strict
      end

      # @return [Boolean] whether unknown keys are rejected
      attr_reader :strict

      # @return [Hash] the field definitions
      attr_reader :fields

      # Define a key with a type and options
      #
      # @param name [Symbol] the key name
      # @param type [Class] the expected type
      # @param default [Object, nil] default value
      # @param optional [Boolean] whether the key is optional
      # @param coerce [Proc, nil] coercion function
      # @return [void]
      def key(name, type, default: nil, optional: false, coerce: nil)
        @fields[name] = {
          type: type,
          default: default,
          optional: optional,
          coerce: coerce
        }
      end

      # Define a nested typed hash schema
      #
      # @param name [Symbol] the key name
      # @param optional [Boolean] whether the nested schema is optional
      # @yield [schema] block receiving a new Schema for the nested hash
      # @return [void]
      def nested(name, optional: false, &block)
        nested_schema = Schema.new(strict: @strict)
        nested_schema.instance_eval(&block)
        @fields[name] = {
          type: Hash,
          optional: optional,
          nested_schema: nested_schema
        }
      end

      # Return the declared top-level key names in definition order
      #
      # Only returns top-level keys — nested schemas are represented by their
      # parent key, not by their inner fields. The returned Array is a fresh
      # copy; mutating it does not affect the schema.
      #
      # @return [Array<Symbol>] the declared top-level key names in definition order
      def keys
        @fields.keys
      end

      # Create a new typed hash instance from data
      #
      # @param data [Hash] the input data
      # @return [Instance] a typed hash instance
      def new(data = {})
        Instance.new(self, data)
      end

      # Deserialize a JSON string into a typed hash instance
      #
      # @param json_str [String] JSON string
      # @return [Instance] a typed hash instance
      def from_json(json_str)
        data = JSON.parse(json_str, symbolize_names: true)
        new(data)
      end
    end
  end
end
