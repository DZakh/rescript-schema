# Ideas draft

- Clean up Caml_option.some, Js_dict.get

- Add S.nullable (?)

- Add S.bigint (?)

- Github Action: Add linter checking that the generated files are up to date (?)

- Don't recreate the object, when nothing should be transformed (???)

- Support optional fields (can have problems with serializing) (???)

- S.mutateWith/S.produceWith (aka immer) (???)

- Add S.function (?) (An alternative for external ???)

```
let trimContract: S.contract<string => string> = S.contract(s => {
  s.fn(s.arg(0, S.string))
}, ~return=S.string)
```

- Add docstrings

- Use internal transform for trim

- Move S.inline to a separate codegen module

## v6.3

- stop reallocate objects without transformations
- Make S.serializeToString super fast
- Add serialiseToString to js api
- Make operations more treeshakable by starting passing the actual operation to the initialOperation function. Or add a condition (verify performance)
- S.validateWith

## v7

- `S.json` -> `S.json(~unsafe: bool)` to improve tree-shaking
- Remove `s.failWithError` since there's `Error.raise` 🤔
- Make `error.reason` tree-shakeable
- Update `Literal` `tagged` to include `text`, `value` and `kind`. So it's more convinient and smaller bundle-size
- Turn `String.email` -> `email`, `String.min` -> `stringMin` for tree-shaking
- Rename `InvalidJsonStruct` error, since after `rescript-struct`->`rescript-schema` it became misleading

## v???

- S.toJSON/S.castToJson ???
- nestedField for object
- s.spread for object
- s.optional for object
- S.produce
- S.mutator
