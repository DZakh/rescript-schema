[![CI](https://github.com/DZakh/rescript-schema/actions/workflows/ci.yml/badge.svg)](https://github.com/DZakh/rescript-schema/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DZakh/rescript-schema/branch/main/graph/badge.svg?token=40G6YKKD6J)](https://codecov.io/gh/DZakh/rescript-schema)
[![npm](https://img.shields.io/npm/dm/rescript-schema)](https://www.npmjs.com/package/rescript-schema)

# ReScript Schema

The fastest composable parser/serializer for ReScript (and TypeScript)

> ⚠️ Be aware that **rescript-schema** uses `eval`. It's usually fine but might not work in some environments like Cloudflare Workers or third-party scripts used on pages with the [script-src](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src) header.

Highlights:

- Combines validation and transformation without a performance loss
- Can transform parsed value back to the initial format (serializing)
- Works with any Js value, not only `Js.Json.t`
- Support for asynchronous transformations
- Immutable API with both result and exception-based operations
- Easy to create _recursive_ schema
- Detailed error messages
- Opt-in strict mode for object schema to prevent excessive fields and many more built-in helpers
- Works with plain JavaScript/TypeScript too! You don't need to use ReScript
- The **fastest** composable validation library in the entire JavaScript ecosystem ([benchmark](https://moltar.github.io/typescript-runtime-type-benchmarks/))
- Small JS footprint & tree-shakable API ([Comparison with Zod and Valibot](./docs/js-usage.md#comparison))

Also, it has declarative API allowing you to use **rescript-schema** as a building block for other tools, such as:

- [rescript-envsafe](https://github.com/DZakh/rescript-envsafe) - Makes sure you don't accidentally deploy apps with missing or invalid environment variables
- [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) - Typesafe JSON schema for ReScript
- Internal form library at [Carla](https://www.carla.se/)

## Documentation

- [For ReScript users](./docs/rescript-usage.md)
- [For JS/TS users](./docs/js-usage.md)
- [For library maintainers](./docs/integration-guide.md)
