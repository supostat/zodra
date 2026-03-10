# Getting Started

> TODO: Write getting started guide once the DSL is implemented.

## Installation

### Ruby Gem

```ruby
# Gemfile
gem "zodra"
```

### Frontend Client

```bash
pnpm add @zodra/client
```

## Quick Example

```ruby
# app/types/invoice.rb
Zodra.type :invoice do
  uuid :id
  string :number
  decimal :amount, min: 0
  enum :status, values: %i[draft sent paid]
  timestamps
end
```

```bash
rake zodra:export
```

Generates TypeScript and Zod schemas ready for your frontend.
