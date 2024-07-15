# Changelog

# Big clean up release

- Added `S.assertOrRaiseWith` or `schema.assert` for JS/TS users. It doesn't return parsed value, which makes the operation 2-3 times faster for some schemas.
- Added `S.setGlobalConfig`. Now it's possible to customize the global behavior of the library:

  - Change the default `unknownKeys` strategy for Object from `Strip` to `Strict`
  - Disable NaN check for numbers

- `S.union` refactoring
  - Drastically improved parsing performance (1x-1000x times faster depending on the case)
  - Returned back async support
  - More specific error messages
  - When serializing to JSON or JSON string the `S.union` now tries to serialize other items when encounters a non-jsonable schema. Before it used to fail the whole union.
- Parse Async refactoring
  - Performance improvements
  - Made it more maintainable and less error-prone
  - Hidden bug fixes
  - Removed `S.parseAsyncInStepsWith` and `S.parseAnyAsyncInStepsWith` to reduce internal library complexity. Create an issue if you need it.
- `S.recursive` refactoring

  - Performance improvements
  - Made it more maintainable and less error-prone
  - Fixed bug with serializing to JSON or JSON string

- For JS/TS users

  - Move operations from functions to `Schema` methods
  - Add `serializeToJsonOrThrow`
  - Improve TS types and make them compatible with generated types from `genType`

- Other improvements

  - `S.jsonString` doesn't fail on getting non-jsonable schema anymore. It will fail on the first serialization run instead
  - Removed `InvalidLiteral` error in favor of `InvalidType`
  - Changed default `name` of `S.literal` schema (`Literal(<value>)` -> `<value>`)
  - Renamed `InvalidJsonStruct` error to `InvalidJsonSchema`, since after `rescript-struct` -> `rescript-schema` it became misleading
  - Update `operation` type to be more detailed and feature it in the error message.
