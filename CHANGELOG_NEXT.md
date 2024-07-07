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
