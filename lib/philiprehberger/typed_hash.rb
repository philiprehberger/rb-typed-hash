# frozen_string_literal: true

require 'json'
require_relative 'typed_hash/version'
require_relative 'typed_hash/schema'
require_relative 'typed_hash/instance'

module Philiprehberger
  module TypedHash
    class Error < StandardError; end
    class FrozenError < Error; end

    # Define a typed hash schema using a block DSL
    #
    # @param strict [Boolean] when true, reject unknown keys
    # @yield [schema] the schema definition block
    # @return [Schema] the defined schema
    def self.define(strict: false, &block)
      schema = Schema.new(strict: strict)
      schema.instance_eval(&block)
      schema
    end
  end
end
