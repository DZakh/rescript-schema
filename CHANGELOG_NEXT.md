# Changelog

- Allow object destructuring in S.variant
- Improve peformance of running serialization to JSON or JSON string for the first time
- Fix serialization to JSON or JSON string for nested recursive schema
- S.jsonString doesn't fail on getting non-jsonable schema anymore. It will fail on the first serialization run instead
- When serializing to JSON or JSON string the S.union now tries to serialize other items when encounters a non-jsonable schema. Before it used to fail the whole union.
- For JS/TS users
  - Move operations from functions to Schema methods
  - Add `serializeToJsonOrThrow`
- Update operation type to be more detailed and feature it in the error message.
- S.union supports schemas with async
- Added `S.assertOrRaiseWith` or `schema.assert` for js/ts users. It doesn't return parsed value, but that makes the function 2-3 times faster, depending on the schema.
- Improved S.recursive implementation
- Added `S.setGlobalConfig`. Now it's possible to customize the behavior of the library:
  - Change the default `unknownKeys` strategy for Object from `Strip` to `Strict`
  - Disable NaN check for numbers
- Removed `parseAsyncInStepsWith` and `parseAnyAsyncInStepsWith` to reduce internal library complexity. Let me know if you need it. I can re-implement it in a future version in a simpler way.
- Refactored parse async. Fixed some bugs and made it more performant.
- Improved performance and errors of S.union schema
- Removed `InvalidLiteral` error in favor of `InvalidType`
- Changed default `name` of `S.literal` schema. `Literal(<value>)` is now `<value>`

// TODO:

- Codegen type
- Codegen schema using type
- Prepare for union refactoring
- Release 7.0.2 with type check fix for recursive schema
- Test GenType compatibility with d.ts
- Clean up error tags
- Set 8.0.x for rescript-schema in ppx deps
- Update github ci to run on "v*.*.\*-patch"
