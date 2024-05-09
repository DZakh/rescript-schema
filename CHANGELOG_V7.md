- Redesigned `Literal` module to make it more effecient
  - The `Literal.t` type was renamed to `literal`, became private and changed structure. Use `S.Literal.parse` to create instances of the type.
  - `Literal.classify` -> `Literal.parse`
  - `Literal.toText` -> `Literal.toString`. Also, started using `.toString` for `Function` literalls and removed spaces for `Dict` and `Array` literals to make them look the same as the `JSON.stringify` output.
- Updated ctx type names to `s` for better autoComplete
  - `effectCtx` -> `s`
  - `Object.ctx` -> `Object.s`
  - `Tuple.ctx` -> `Tuple.s`
  - `schemaCtx` -> `Schema.s`
  - `catchCtx` -> `Catch.s`
- Added `serializeToJsonStringOrRaiseWith`
- Allow to create `S.union` with single item

Plan for V7:

- Tree-shakable error reasons (postponed)
- Tree-shakable built-in refinements (postponed)
- 2x faster serializeToJsonString
- Add S.bigint
- // TODO: Update doc with changes
