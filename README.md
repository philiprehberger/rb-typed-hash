# philiprehberger-typed_hash

[![Tests](https://github.com/philiprehberger/rb-typed-hash/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-typed-hash/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-typed_hash.svg)](https://rubygems.org/gems/philiprehberger-typed_hash)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-typed-hash)](https://github.com/philiprehberger/rb-typed-hash/commits/main)

Hash with per-key type declarations, coercion, validation, nested schemas, and JSON serialization

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

### Nested Schemas

```ruby
schema = Philiprehberger::TypedHash.define do
  key :name, String
  nested :address do
    key :street, String
    key :city, String
  end
end

user = schema.new(name: 'Alice', address: { street: '123 Main St', city: 'Springfield' })
user[:address][:street]  # => '123 Main St'
```

### Pick and Omit

```ruby
full = schema.new(name: 'Alice', age: 30, email: 'alice@example.com')
picked = full.pick(:name, :email)   # only :name and :email
omitted = full.omit(:email)         # everything except :email
```

### JSON Serialization

```ruby
instance = schema.new(name: 'Alice', age: 30)
json = instance.to_json              # => '{"name":"Alice","age":30}'
restored = schema.from_json(json)    # => Instance
```

### Freeze

```ruby
instance = schema.new(name: 'Alice', age: 30)
instance.freeze
instance[:name] = 'Bob'  # => raises Philiprehberger::TypedHash::FrozenError
```

### Diff

```ruby
a = schema.new(name: 'Alice', age: 30)
b = schema.new(name: 'Alice', age: 35)
a.diff(b)  # => { age: { old: 30, new: 35 } }
```

### Merging

```ruby
base = schema.new(name: 'Alice', age: 25)
updated = base.merge(age: 30)
updated[:age]  # => 30
```

### Key Membership

```ruby
schema = Philiprehberger::TypedHash::Schema.new
schema.key(:name, String)
schema.key(:age, Integer, optional: true)

instance = schema.new(name: 'Alice')
instance.key?(:name)  # => true
instance.key?('name') # => true (string form works)
instance.key?(:age)   # => false
instance.key?(:foo)   # => false
```

### Schema introspection

```ruby
schema = Philiprehberger::TypedHash.define do
  key :name, String
  nested :address do
    key :street, String
  end
  key :age, Integer
end

schema.keys  # => [:name, :address, :age]
```

`Schema#keys` returns the declared top-level key names in definition order.
Nested schemas contribute only their parent key — inner fields are not
included.

## API

### `TypedHash`

| Method | Description |
|--------|-------------|
| `.define(strict:) { }` | Define a schema with a block DSL |

### `Schema`

| Method | Description |
|--------|-------------|
| `key :name, Type, opts` | Declare a typed key with options |
| `nested :name, opts, &block` | Define a nested typed hash schema |
| `#new(data)` | Create a typed hash instance |
| `#from_json(str)` | Deserialize a JSON string into a typed hash instance |
| `#keys` | Return the declared top-level key names in definition order |

### `Instance`

| Method | Description |
|--------|-------------|
| `#[key]` | Access a value by key |
| `#[key] = value` | Set a value by key (raises if frozen) |
| `#key?(key)` | True when `key` is present in the instance data (accepts Symbol or String) |
| `#valid?` | Check if the instance passes validation |
| `#errors` | Return validation error messages |
| `#to_h` | Convert to a plain hash |
| `#to_json` | Serialize to a JSON string |
| `#merge(other)` | Merge with another hash or instance |
| `#pick(*keys)` | Return new instance with only the specified keys |
| `#omit(*keys)` | Return new instance without the specified keys |
| `#freeze` | Make the instance immutable |
| `#frozen?` | Check if the instance is frozen |
| `#diff(other)` | Return hash of changed keys with old and new values |

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
