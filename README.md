[![CI](https://github.com/DZakh/rescript-schema/actions/workflows/ci.yml/badge.svg)](https://github.com/DZakh/rescript-schema/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DZakh/rescript-schema/branch/main/graph/badge.svg?token=40G6YKKD6J)](https://codecov.io/gh/DZakh/rescript-schema)
[![npm](https://img.shields.io/npm/dm/rescript-schema)](https://www.npmjs.com/package/rescript-schema)

# ReScript Schema

The fastest composable parser/serializer for ReScript and TypeScript

> ⚠️ Be aware that **rescript-schema** uses `eval` for parsing. It's usually fine but might not work in some environments like Cloudflare Workers or third-party scripts used on pages with the [script-src](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src) header.

Highlights:

- Combines validation and transformation without a performance loss
- Can transform parsed value back to the initial format (serializing)
- Works with any Js value, not only `Js.Json.t`
- Support for asynchronous transformations
- Immutable API with both result and exception-based operations
- Easy to create _recursive_ schema
- Detailed error messages
- Opt-in strict mode for object schema to prevent excessive fields and many more built-in helpers
- Opt-in PPX to generate schema from type
- Works with plain JavaScript/TypeScript too! You don't need to use ReScript
- The **fastest** composable validation library in the entire JavaScript ecosystem ([benchmark](https://moltar.github.io/typescript-runtime-type-benchmarks/))
- Small JS footprint & tree-shakable API ([Comparison with Zod and Valibot](#comparison))

Also, it has declarative API allowing you to use **rescript-schema** as a building block for other tools, such as:

- [rescript-rest](https://github.com/DZakh/rescript-rest) - RPC-like client, contract, and server implementation for a pure REST API
- [rescript-envsafe](https://github.com/DZakh/rescript-envsafe) - Makes sure you don't accidentally deploy apps with missing or invalid environment variables
- [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) - Typesafe JSON schema for ReScript
- Internal form library at [Carla](https://www.carla.se/)

## Documentation

- [For ReScript users](/docs/rescript-usage.md)
- [For PPX users](/packages/rescript-schema-ppx/README.md)
- [For JS/TS users](/docs/js-usage.md)
- [For library maintainers](/docs/integration-guide.md)

## Comparison

Instead of relying on a few large functions with many methods, **rescript-schema** follows [Valibot](https://github.com/fabian-hiller/valibot)'s approach, where API design and source code is based on many small and independent functions, each with just a single task. This modular design has several advantages.

For example, this allows a bundler to use the import statements to remove code that is not needed. This way, only the code that is actually used gets into your production build. This can reduce the bundle size by up to 2 times compared to [Zod](https://github.com/colinhacks/zod).

Besides the individual bundle size, the overall size of the library is also significantly smaller.

At the same time **rescript-schema** is the fastest composable validation library in the entire JavaScript ecosystem. This is achieved because of the JIT approach when an ultra optimized validator is created using `eval`.

|                                           | rescript-schema@7.0.0 | Zod@3.22.2      | Valibot@0.32.0 |
| ----------------------------------------- | --------------------- | --------------- | -------------- |
| **Total size** (minified + gzipped)       | 9.82 kB               | 14.6 kB         | 9.88 kB        |
| **Example size** (minified + gzipped)     | 4.98 kB               | 12.9 kB         | 1.22 B         |
| **Nested object parsing**                 | 156,244 ops/ms        | 1,304 ops/ms    | 3,822 ops/ms   |
| **Create schema + Nested object parsing** | 56 ops/ms             | 112 ops/ms      | 2,475 ops/ms   |
| **Eval-free**                             | ❌                    | ✅              | ✅             |
| **Codegen-free** (Doesn't need compiler)  | ✅                    | ✅              | ✅             |
| **Ecosystem**                             | ⭐️                   | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️      |
