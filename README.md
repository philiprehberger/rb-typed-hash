# philiprehberger-typed_hash

[![Tests](https://github.com/philiprehberger/rb-typed-hash/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-typed-hash/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-typed_hash.svg)](https://rubygems.org/gems/philiprehberger-typed_hash)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-typed-hash)](https://github.com/philiprehberger/rb-typed-hash/commits/main)

Hash with per-key type declarations, coercion, and validation

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-typed_hash"
```

Or install directly:

```bash
gem install philiprehberger-typed_hash
```

## Usage

```ruby
require "philiprehberger/typed_hash"

UserSchema = Philiprehberger::TypedHash.define do
  key :name, String
  key :age, Integer
  key :email, String
end

user = UserSchema.new(name: 'Alice', age: 30, email: 'alice@example.com')
user[:name]   # => 'Alice'
user.valid?   # => true
```

### Default Values

```ruby
schema = Philiprehberger::TypedHash.define do
  key :name, String
  key :role, String, default: 'user'
end

instance = schema.new(name: 'Alice')
instance[:role]  # => 'user'
```

### Optional Keys

```ruby
schema = Philiprehberger::TypedHash.define do
  key :name, String
  key :nickname, String, optional: true
end

schema.new(name: 'Alice').valid?  # => true
```

### Coercion

```ruby
schema = Philiprehberger::TypedHash.define do
  key :count, Integer, coerce: ->(v) { Integer(v) }
  key :active, TrueClass, coerce: ->(v) { v == 'true' }
end

instance = schema.new(count: '42', active: 'true')
instance[:count]  # => 42
```

### Strict Mode

```ruby
schema = Philiprehberger::TypedHash.define(strict: true) do
  key :name, String
end

instance = schema.new(name: 'Alice', extra: 'value')
instance.valid?   # => false
instance.errors   # => ['unknown key: extra']
```

### Merging

```ruby
base = schema.new(name: 'Alice', age: 25)
updated = base.merge(age: 30)
updated[:age]  # => 30
```

## API

### `TypedHash`

| Method | Description |
|--------|-------------|
| `.define(strict:) { }` | Define a schema with a block DSL |

### `Schema`

| Method | Description |
|--------|-------------|
| `key :name, Type, opts` | Declare a typed key with options |
| `#new(data)` | Create a typed hash instance |

### `Instance`

| Method | Description |
|--------|-------------|
| `#[key]` | Access a value by key |
| `#valid?` | Check if the instance passes validation |
| `#errors` | Return validation error messages |
| `#to_h` | Convert to a plain hash |
| `#merge(other)` | Merge with another hash or instance |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-typed-hash)

🐛 [Report issues](https://github.com/philiprehberger/rb-typed-hash/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-typed-hash/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
