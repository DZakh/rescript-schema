# Ideas draft

- Clean up Caml_option.some, Js_dict.get

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

## v7

- stop reallocate objects without transformations
- Make S.serializeToJsonString super fast
- Make operations more treeshakable by starting passing the actual operation to the initialOperation function. Or add a condition (verify performance)
- Remove `s.failWithError` since there's `Error.raise` 🤔
- Turn `String.email` -> `email`, `String.min` -> `stringMin` for tree-shaking
- Rename `InvalidJsonStruct` error, since after `rescript-struct`->`rescript-schema` it became misleading
- Add S.bigint

## v???

- S.validateWith
- Make `error.reason` tree-shakeable
- Add serializeToJsonString to js api
- S.toJSON/S.castToJson ???
- nestedField for object
- s.spread for object
- s.optional for object
- S.produce
- S.mutator
