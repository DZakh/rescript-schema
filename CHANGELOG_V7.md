# ReScript Schema V7 🔥

## `S.object` superpowers 🦸

### `s.flatten`

Now, it's possible to spread/flatten an object schema in another object schema, allowing you to reuse schemas in a more powerful way.

```rescript
type entityData = {
  name: string,
  age: int,
}
type entity = {
  id: string,
  ...entityData,
}

let entityDataSchema = S.object(s => {
  name: s.field("name", S.string),
  age: s.field("age", S.int),
})
let entitySchema = S.object(s => {
  let {name, age} = s.flatten(entityDataSchema)
  {
    id: s.field("id", S.string),
    name,
    age,
  }
})
```

### `s.nestedField`

A new nice way to parse nested fields:

```rescript
let schema = S.object(s => {
  {
    id: s.field("id", S.string),
    name: s.nestedField("data", "name", S.string)
    age: s.nestedField("data", "name", S.int),
  }
})
```

### Object destructuring

Also, it's possible to destructure object field schemas inside of the definition. You could also notice it in the `s.flatten` example 😁

```rescript
let entitySchema = S.object(s => {
  let {name, age} = s.field("data", entityDataSchema)
  {
    id: s.field("id", S.string),
    name,
    age,
  }
})
```

> 🧠 While the example with `s.flatten` expect an object with the type `{id: string, name: string, age: int}`, the example above and with `s.nestedField` will expect an object with the type `{id: string, data: {name: string, age: int}}`.

### Extend field with another object schema

You can define object field multiple times to extend it with more fields:

```rescript
let entitySchema = S.object(s => {
  let {name, age} = s.field("data", entityDataSchema)
  let additionalData = s.field("data", s => {
    "friends": s.field("friends", S.array(S.string))
  })
  {
    id: s.field("id", S.string),
    name,
    age,
    friends: additionalData["friends"],
  }
})
```

> 🧠 Destructuring works only with not-transformed object schemas. Be careful since it's not protected by type system.

## Autocomplete improvements ⌨️

Updated context type names to `s` for better auto-complete in your IDE.

- `effectCtx` -> `s`
- `Object.ctx` -> `Object.s`
- `Tuple.ctx` -> `Tuple.s`
- `schemaCtx` -> `Schema.s`
- `catchCtx` -> `Catch.s`

## `S.json` redesign 💽

Added unsafe mode for `S.json`:

- `S.json` -> `S.json(~validate: bool)`
- More flexible
- Improved tree-shaking
- Tools using `rescript-schema` can get the info from the `tagged` type: `JSON` -> `JSON({validated: bool})`

## Other cool changes and sometimes breaking 💣

- Added `serializeToJsonStringOrRaiseWith`
- Allow to create `S.union` with a single item
- Removed `s.failWithError`. Use `S.Error.raise` instead
- PPX: Removed `@schema` for type expressions. Use `@s.matches` instead.
- Removed async support for `S.union`. Please create an issue if you used the feature
- Improved parsing performance of `S.array` and `S.dict` ~3 times
- Automatic serializing stopped working for tuples/objects/unions of literals. Use `S.literal` instead
- Removed `InvalidTupleSize` error code in favor of `InvalidType`
- Changed payload of `Object` and `Tuple` variants in the `tagged` type
- Redesigned `Literal` module to make it more efficient

  - The `S.Literal.t` type was renamed to `S.literal`, became private and changed structure. Use `S.Literal.parse` to create instances of the type
  - `S.Literal.classify` -> `S.Literal.parse`
  - `S.Literal.toText` -> `S.Literal.toString`. Also, started using `.toString` for `Function` literals and removed spaces for `Dict` and `Array` literals to make them look the same as the `JSON.stringify` output

- Moved built-in refinements from nested modules to improve tree-shaking:

  - `S.Int.min` -> `S.intMin`
  - `S.Int.max` -> `S.intMax`
  - `S.Int.port` -> `S.port`

  - `S.Float.min` -> `S.floatMin`
  - `S.Float.max` -> `S.floatMax`

  - `S.Array.min` -> `S.arrayMinLength`
  - `S.Array.max` -> `S.arrayMaxLength`
  - `S.Array.length` -> `S.arrayLength`

  - `S.String.min` -> `S.stringMinLength`
  - `S.String.max` -> `S.stringMaxLength`
  - `S.String.length` -> `S.stringLength`
  - `S.String.email` -> `S.email`
  - `S.String.uuid` -> `S.uuid`
  - `S.String.cuid` -> `S.cuid`
  - `S.String.url` -> `S.url`
  - `S.String.pattern` -> `S.pattern`
  - `S.String.datetime` -> `S.datetime`
  - `S.String.trim` -> `S.trim`

  - `S.Int.min` -> `S.intMin`
  - `S.Int.max` -> `S.intMax`

  - `S.Number.max` -> `S.numberMax`/`S.integerMax`
  - `S.Number.min` -> `S.numberMin`/`S.integerMin`