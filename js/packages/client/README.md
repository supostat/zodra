# @zodra/client

Type-safe API client for [Zodra](https://github.com/supostat/zodra) — auto-generated from Rails contracts.

⚠️ **Work in progress** — for evaluation purposes only.

## Installation

```bash
pnpm add @zodra/client zod
```

## Usage

```typescript
import { createApiClient } from '@zodra/client'
import { contracts } from './zodra/contracts'

const api = createApiClient({
  baseUrl: '/api/v1',
  contracts,
})

const { data } = await api.products.index()
const { data: product } = await api.products.show({ id: '...' })
```

## Requirements

- Zod >= 4.3.6

## License

[MIT](../../LICENSE)
