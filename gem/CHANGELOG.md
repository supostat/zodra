# Changelog

## 0.1.0 (2026-03-11)

Initial release.

- Type DSL: objects, enums, unions with attributes (optional, nullable, defaults, constraints, enum)
- Type composition: `from:`, `pick:`, `omit:`, `partial:`
- Contracts: params and response definitions per action
- Resource routing: `Zodra.api` with nested resources and custom actions
- Params validation: strict by default, coercion, constraints
- Response serialization: `{ data: ... }` / `{ data: [...], meta: ... }` envelope
- Controller mixin: `zodra_params`, `zodra_respond`, error handling
- TypeScript export: interfaces from type definitions
- Zod export: schemas with constraints (min, max, enum)
- Auto-generated header in exported files
- Rails integration: Railtie, rake tasks, Zeitwerk
