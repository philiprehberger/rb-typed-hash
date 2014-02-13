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
end
