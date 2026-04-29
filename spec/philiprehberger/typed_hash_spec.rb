# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::TypedHash do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  describe '.define' do
    it 'returns a Schema' do
      schema = described_class.define do
        key :name, String
      end
      expect(schema).to be_a(described_class::Schema)
    end
  end

  describe 'basic usage' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer
      end
    end

    it 'creates a valid instance' do
      instance = schema.new(name: 'Alice', age: 30)
      expect(instance.valid?).to be(true)
      expect(instance[:name]).to eq('Alice')
      expect(instance[:age]).to eq(30)
    end

    it 'reports type errors' do
      instance = schema.new(name: 123, age: 'thirty')
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('name must be a String, got Integer')
      expect(instance.errors).to include('age must be a Integer, got String')
    end

    it 'reports missing required keys' do
      instance = schema.new(name: 'Alice')
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('age is required')
    end
  end

  describe 'optional keys' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :nickname, String, optional: true
      end
    end

    it 'allows missing optional keys' do
      instance = schema.new(name: 'Alice')
      expect(instance.valid?).to be(true)
      expect(instance[:nickname]).to be_nil
    end
  end

  describe 'default values' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :role, String, default: 'user'
      end
    end

    it 'uses default when key is missing' do
      instance = schema.new(name: 'Alice')
      expect(instance[:role]).to eq('user')
    end

    it 'overrides default when key is provided' do
      instance = schema.new(name: 'Alice', role: 'admin')
      expect(instance[:role]).to eq('admin')
    end
  end

  describe 'coercion' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :count, Integer, coerce: ->(v) { Integer(v) }
      end
    end

    it 'coerces values before validation' do
      instance = schema.new(count: '42')
      expect(instance.valid?).to be(true)
      expect(instance[:count]).to eq(42)
    end

    it 'reports coercion failures' do
      instance = schema.new(count: 'not_a_number')
      expect(instance.valid?).to be(false)
      expect(instance.errors.any? { |e| e.include?('coercion failed') }).to be(true)
    end
  end

  describe 'strict mode' do
    let(:schema) do
      Philiprehberger::TypedHash.define(strict: true) do
        key :name, String
      end
    end

    it 'rejects unknown keys' do
      instance = schema.new(name: 'Alice', extra: 'value')
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('unknown key: extra')
    end

    it 'allows known keys only' do
      instance = schema.new(name: 'Alice')
      expect(instance.valid?).to be(true)
    end
  end

  describe '#to_h' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer
      end
    end

    it 'converts to a plain hash' do
      instance = schema.new(name: 'Alice', age: 30)
      expect(instance.to_h).to eq({ name: 'Alice', age: 30 })
    end
  end

  describe '#merge' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer, default: 0
      end
    end

    it 'merges with a hash' do
      instance = schema.new(name: 'Alice', age: 25)
      merged = instance.merge(age: 30)
      expect(merged[:name]).to eq('Alice')
      expect(merged[:age]).to eq(30)
    end

    it 'merges with another instance' do
      a = schema.new(name: 'Alice', age: 25)
      b = schema.new(name: 'Bob', age: 30)
      merged = a.merge(b)
      expect(merged[:name]).to eq('Bob')
      expect(merged[:age]).to eq(30)
    end
  end

  describe 'string keys' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
      end
    end

    it 'symbolizes string keys' do
      instance = schema.new('name' => 'Alice')
      expect(instance.valid?).to be(true)
      expect(instance[:name]).to eq('Alice')
    end
  end

  # --- Expanded tests ---

  describe 'empty data with all required keys' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :a, String
        key :b, Integer
      end
    end

    it 'reports all missing required keys for empty hash' do
      instance = schema.new({})
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('a is required')
      expect(instance.errors).to include('b is required')
    end

    it 'returns empty hash from to_h when all keys missing' do
      instance = schema.new({})
      expect(instance.to_h).to eq({})
    end
  end

  describe 'multiple type violations' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer
        key :active, TrueClass, optional: true
      end
    end

    it 'collects multiple errors at once' do
      instance = schema.new(name: 42, age: 'old', active: 'yes')
      expect(instance.valid?).to be(false)
      expect(instance.errors.size).to eq(3)
    end
  end

  describe 'coercion with type mismatch after coercion' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :value, Integer, coerce: lambda(&:to_s)
      end
    end

    it 'reports type error when coerced value does not match type' do
      instance = schema.new(value: 42)
      expect(instance.valid?).to be(false)
      expect(instance.errors.any? { |e| e.include?('must be a Integer') }).to be(true)
    end
  end

  describe 'coercion exception message' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :data, Hash, coerce: ->(_v) { raise ArgumentError, 'bad input' }
      end
    end

    it 'includes the exception message in coercion error' do
      instance = schema.new(data: 'something')
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('data coercion failed: bad input')
    end
  end

  describe 'strict mode with multiple unknown keys' do
    let(:schema) do
      Philiprehberger::TypedHash.define(strict: true) do
        key :name, String
      end
    end

    it 'reports each unknown key separately' do
      instance = schema.new(name: 'Alice', foo: 1, bar: 2)
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('unknown key: foo')
      expect(instance.errors).to include('unknown key: bar')
    end
  end

  describe 'non-strict mode ignores unknown keys' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
      end
    end

    it 'does not report unknown keys in non-strict mode' do
      instance = schema.new(name: 'Alice', extra: 'value')
      expect(instance.valid?).to be(true)
    end

    it 'does not include unknown keys in to_h' do
      instance = schema.new(name: 'Alice', extra: 'value')
      expect(instance.to_h).to eq({ name: 'Alice' })
    end
  end

  describe 'to_h returns a copy' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :items, Array
      end
    end

    it 'does not allow mutation through to_h' do
      instance = schema.new(items: [1, 2, 3])
      hash = instance.to_h
      hash[:items] = []
      expect(instance[:items]).to eq([1, 2, 3])
    end
  end

  describe 'errors returns a copy' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
      end
    end

    it 'does not allow mutation through errors' do
      instance = schema.new({})
      errors = instance.errors
      errors.clear
      expect(instance.errors).not_to be_empty
    end
  end

  describe 'default value with nil' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :tag, String, optional: true
        key :count, Integer, default: nil
      end
    end

    it 'treats nil default as missing and reports required' do
      instance = schema.new({})
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('count is required')
    end

    it 'does not report optional key without default' do
      instance = schema.new(count: 5)
      expect(instance.valid?).to be(true)
      expect(instance[:tag]).to be_nil
    end
  end

  describe 'merge produces a validated instance' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer, default: 0
      end
    end

    it 'validates merged result' do
      original = schema.new(name: 'Alice', age: 25)
      merged = original.merge(age: 'not_a_number')
      expect(merged.valid?).to be(false)
      expect(merged.errors).to include('age must be a Integer, got String')
    end

    it 'merged instance is independent of original' do
      original = schema.new(name: 'Alice', age: 25)
      merged = original.merge(name: 'Bob')
      expect(original[:name]).to eq('Alice')
      expect(merged[:name]).to eq('Bob')
    end
  end

  describe 'schema with many types' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :str, String
        key :int, Integer
        key :flt, Float
        key :arr, Array
        key :hsh, Hash
        key :sym, Symbol
      end
    end

    it 'validates all types correctly' do
      instance = schema.new(str: 'hello', int: 42, flt: 3.14, arr: [1], hsh: { a: 1 }, sym: :ok)
      expect(instance.valid?).to be(true)
    end

    it 'rejects wrong types for all fields' do
      instance = schema.new(str: 1, int: 'x', flt: 'x', arr: 'x', hsh: 'x', sym: 'x')
      expect(instance.valid?).to be(false)
      expect(instance.errors.size).to eq(6)
    end
  end

  describe 'schema strict attribute' do
    it 'exposes strict as false by default' do
      schema = Philiprehberger::TypedHash.define { key :a, String }
      expect(schema.strict).to be(false)
    end

    it 'exposes strict as true when set' do
      schema = Philiprehberger::TypedHash.define(strict: true) { key :a, String }
      expect(schema.strict).to be(true)
    end
  end

  describe 'schema fields attribute' do
    it 'exposes field definitions' do
      schema = Philiprehberger::TypedHash.define do
        key :name, String, optional: true
      end
      expect(schema.fields[:name][:type]).to eq(String)
      expect(schema.fields[:name][:optional]).to be(true)
    end
  end

  describe 'nested schemas' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        nested :address do
          key :street, String
          key :city, String
        end
      end
    end

    it 'validates a valid nested hash' do
      instance = schema.new(name: 'Alice', address: { street: '123 Main St', city: 'Springfield' })
      expect(instance.valid?).to be(true)
      expect(instance[:address][:street]).to eq('123 Main St')
      expect(instance[:address][:city]).to eq('Springfield')
    end

    it 'reports errors for invalid nested fields' do
      instance = schema.new(name: 'Alice', address: { street: 123, city: 'Springfield' })
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('address.street must be a String, got Integer')
    end

    it 'reports error when nested value is not a Hash' do
      instance = schema.new(name: 'Alice', address: 'not a hash')
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('address must be a Hash, got String')
    end

    it 'reports error when required nested field is missing' do
      instance = schema.new(name: 'Alice')
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('address is required')
    end

    it 'reports missing keys inside nested hash' do
      instance = schema.new(name: 'Alice', address: { street: '123 Main St' })
      expect(instance.valid?).to be(false)
      expect(instance.errors).to include('address.city is required')
    end

    context 'with optional nested schema' do
      let(:schema) do
        Philiprehberger::TypedHash.define do
          key :name, String
          nested :metadata, optional: true do
            key :source, String
          end
        end
      end

      it 'allows missing optional nested schema' do
        instance = schema.new(name: 'Alice')
        expect(instance.valid?).to be(true)
        expect(instance[:metadata]).to be_nil
      end

      it 'validates optional nested schema when provided' do
        instance = schema.new(name: 'Alice', metadata: { source: 'web' })
        expect(instance.valid?).to be(true)
        expect(instance[:metadata][:source]).to eq('web')
      end
    end

    it 'converts nested instances in to_h' do
      instance = schema.new(name: 'Alice', address: { street: '123 Main St', city: 'Springfield' })
      hash = instance.to_h
      expect(hash[:address]).to eq({ street: '123 Main St', city: 'Springfield' })
      expect(hash[:address]).to be_a(Hash)
    end
  end

  describe '#pick' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer, optional: true
        key :email, String, optional: true
      end
    end

    it 'returns a new instance with only the specified keys' do
      instance = schema.new(name: 'Alice', age: 30, email: 'alice@example.com')
      picked = instance.pick(:name, :email)
      expect(picked[:name]).to eq('Alice')
      expect(picked[:email]).to eq('alice@example.com')
      expect(picked[:age]).to be_nil
    end

    it 'does not mutate the original instance' do
      instance = schema.new(name: 'Alice', age: 30, email: 'alice@example.com')
      instance.pick(:name)
      expect(instance[:age]).to eq(30)
    end
  end

  describe '#omit' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer, optional: true
        key :email, String, optional: true
      end
    end

    it 'returns a new instance without the specified keys' do
      instance = schema.new(name: 'Alice', age: 30, email: 'alice@example.com')
      omitted = instance.omit(:age, :email)
      expect(omitted[:name]).to eq('Alice')
      expect(omitted[:age]).to be_nil
      expect(omitted[:email]).to be_nil
    end

    it 'does not mutate the original instance' do
      instance = schema.new(name: 'Alice', age: 30, email: 'alice@example.com')
      instance.omit(:age)
      expect(instance[:age]).to eq(30)
    end
  end

  describe 'JSON serialization' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer
      end
    end

    it 'serializes to JSON' do
      instance = schema.new(name: 'Alice', age: 30)
      json = instance.to_json
      parsed = JSON.parse(json)
      expect(parsed).to eq({ 'name' => 'Alice', 'age' => 30 })
    end

    it 'deserializes from JSON' do
      json = '{"name":"Alice","age":30}'
      instance = schema.from_json(json)
      expect(instance.valid?).to be(true)
      expect(instance[:name]).to eq('Alice')
      expect(instance[:age]).to eq(30)
    end

    it 'roundtrips through JSON' do
      original = schema.new(name: 'Bob', age: 25)
      json = original.to_json
      restored = schema.from_json(json)
      expect(restored.to_h).to eq(original.to_h)
    end

    it 'validates deserialized data' do
      json = '{"name":123,"age":"not_a_number"}'
      instance = schema.from_json(json)
      expect(instance.valid?).to be(false)
    end
  end

  describe '#freeze' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer
      end
    end

    it 'prevents modification after freeze' do
      instance = schema.new(name: 'Alice', age: 30)
      instance.freeze
      expect { instance[:name] = 'Bob' }.to raise_error(Philiprehberger::TypedHash::FrozenError)
    end

    it 'reports frozen state' do
      instance = schema.new(name: 'Alice', age: 30)
      expect(instance.frozen?).to be(false)
      instance.freeze
      expect(instance.frozen?).to be(true)
    end

    it 'allows reads after freeze' do
      instance = schema.new(name: 'Alice', age: 30)
      instance.freeze
      expect(instance[:name]).to eq('Alice')
    end

    it 'returns self from freeze' do
      instance = schema.new(name: 'Alice', age: 30)
      expect(instance.freeze).to be(instance)
    end
  end

  describe '#keys' do
    it 'returns an empty array for an empty schema' do
      schema = Philiprehberger::TypedHash.define {}
      expect(schema.keys).to eq([])
    end

    it 'returns declared keys in definition order' do
      schema = Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer
        key :email, String, optional: true
      end
      expect(schema.keys).to eq(%i[name age email])
    end

    it 'only returns top-level keys for nested schemas' do
      schema = Philiprehberger::TypedHash.define do
        key :name, String
        nested :address do
          key :street, String
          key :city, String
        end
        key :age, Integer
      end
      expect(schema.keys).to eq(%i[name address age])
    end

    it 'does not allow mutation through keys' do
      schema = Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer
      end
      keys = schema.keys
      keys.clear
      expect(schema.keys).to eq(%i[name age])
    end
  end

  describe '#diff' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer
        key :email, String, optional: true
      end
    end

    it 'returns changed keys with old and new values' do
      a = schema.new(name: 'Alice', age: 30)
      b = schema.new(name: 'Alice', age: 35)
      result = a.diff(b)
      expect(result).to eq({ age: { old: 30, new: 35 } })
    end

    it 'returns empty hash when instances are equal' do
      a = schema.new(name: 'Alice', age: 30)
      b = schema.new(name: 'Alice', age: 30)
      expect(a.diff(b)).to eq({})
    end

    it 'detects added keys' do
      a = schema.new(name: 'Alice', age: 30)
      b = schema.new(name: 'Alice', age: 30, email: 'alice@example.com')
      result = a.diff(b)
      expect(result).to eq({ email: { old: nil, new: 'alice@example.com' } })
    end

    it 'detects removed keys' do
      a = schema.new(name: 'Alice', age: 30, email: 'alice@example.com')
      b = schema.new(name: 'Alice', age: 30)
      result = a.diff(b)
      expect(result).to eq({ email: { old: 'alice@example.com', new: nil } })
    end

    it 'detects multiple changes' do
      a = schema.new(name: 'Alice', age: 30)
      b = schema.new(name: 'Bob', age: 25)
      result = a.diff(b)
      expect(result.keys).to contain_exactly(:name, :age)
    end
  end

  describe '#key?' do
    let(:schema) do
      Philiprehberger::TypedHash.define do
        key :name, String
        key :age, Integer, optional: true
      end
    end

    it 'returns true for a declared key with a value' do
      instance = schema.new(name: 'Alice')
      expect(instance.key?(:name)).to be(true)
    end

    it 'returns false for a declared optional key without a value' do
      instance = schema.new(name: 'Alice')
      expect(instance.key?(:age)).to be(false)
    end

    it 'returns false for an undeclared key' do
      instance = schema.new(name: 'Alice')
      expect(instance.key?(:foo)).to be(false)
    end

    it 'accepts string keys equivalently to symbol keys' do
      instance = schema.new(name: 'Alice')
      expect(instance.key?('name')).to be(true)
      expect(instance.key?('age')).to be(false)
      expect(instance.key?('foo')).to be(false)
    end
  end
end
