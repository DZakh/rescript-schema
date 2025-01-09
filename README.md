[![CI](https://github.com/DZakh/rescript-schema/actions/workflows/ci.yml/badge.svg)](https://github.com/DZakh/rescript-schema/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DZakh/rescript-schema/branch/main/graph/badge.svg?token=40G6YKKD6J)](https://codecov.io/gh/DZakh/rescript-schema)
[![npm](https://img.shields.io/npm/dm/rescript-schema)](https://www.npmjs.com/package/rescript-schema)

# ReScript Schema 🧬

The fastest parser in the entire JavaScript ecosystem with a focus on small bundle size and top-notch DX.

> ⚠️ Be aware that **rescript-schema** uses `eval` for parsing. It's usually fine but might not work in some environments like Cloudflare Workers or third-party scripts used on pages with the [script-src](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src) header.

Highlights:

- Works with plain JavaScript, TypeScript, and ReScript. You don't need to use any compiler.
- The **fastest** parsing and validation library in the entire JavaScript ecosystem ([benchmark](https://moltar.github.io/typescript-runtime-type-benchmarks/))
- Small JS footprint & tree-shakable API ([Comparison with Zod and Valibot](#comparison))
- Describe transformations in a schema without a performance loss
- Reverse schema and convert values to the initial format (serializing)
- Detailed and easy to understand error messages
- Support for asynchronous transformations
- Immutable API with 100+ different operation combinations
- Easy to create _recursive_ schema
- Opt-in strict mode for object schema to prevent unknown fields with ability to change it for the whole project
- Opt-in ReScript PPX to generate schema from type definition

Also, it has declarative API allowing you to use **rescript-schema** as a building block for other tools, such as:

- [rescript-rest](https://github.com/DZakh/rescript-rest) - RPC-like client, contract, and server implementation for a pure REST API
- [rescript-envsafe](https://github.com/DZakh/rescript-envsafe) - Makes sure you don't accidentally deploy apps with missing or invalid environment variables
- [rescript-json-schema](https://github.com/DZakh/rescript-json-schema) - Typesafe JSON schema for ReScript
- Internal form library at [Carla](https://www.carla.se/)

## Documentation

- [For JS/TS users](/docs/js-usage.md)
- [For ReScript users](/docs/rescript-usage.md)
- [For PPX users](/packages/rescript-schema-ppx/README.md)
- [For library maintainers](/docs/integration-guide.md)

## Content

- Building and consuming REST API in ReScript with rescript-rest and Fastify ([YouTube](https://youtu.be/37FY6a-zY20?si=72zT8Gecs5vmDPlD))
- ReScript Schema V9 Changes Overview ([Dev.to](https://dev.to/dzakh/rescript-schema-v9-zod-like-library-to-the-next-level-1dn6))

## Comparison

Instead of relying on a few large functions with many methods, **rescript-schema** follows [Valibot](https://github.com/fabian-hiller/valibot)'s approach, where API design and source code is based on many small and independent functions, each with just a single task. This modular design has several advantages.

For example, this allows a bundler to use the import statements to remove code that is not needed. This way, only the code that is actually used gets into your production build. This can reduce the bundle size by up to 2 times compared to [Zod](https://github.com/colinhacks/zod).

Besides the individual bundle size, the overall size of the library is also significantly smaller.

At the same time **rescript-schema** is the fastest composable validation library in the entire JavaScript ecosystem. This is achieved because of the JIT approach when an ultra optimized validator is created using `eval`.

|                                          | rescript-schema@9.0.0 | Zod@3.24.1      | Valibot@0.42.1 |
| ---------------------------------------- | --------------------- | --------------- | -------------- |
| **Total size** (minified + gzipped)      | 11 kB                 | 14.8 kB         | 10.5 kB        |
| **Example size** (minified + gzipped)    | 4.45 kB               | 13.5 kB         | 1.22 kB        |
| **Parse with the same schema**           | 100,070 ops/ms        | 1,277 ops/ms    | 3,881 ops/ms   |
| **Create schema & parse once**           | 179 ops/ms            | 112 ops/ms      | 2,521 ops/ms   |
| **Eval-free**                            | ❌                    | ✅              | ✅             |
| **Codegen-free** (Doesn't need compiler) | ✅                    | ✅              | ✅             |
| **Ecosystem**                            | ⭐️⭐️                | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️      |
