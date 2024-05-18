# Ideas draft

- Clean up Caml_option.some, Js_dict.get

- Github Action: Add linter checking that the generated files are up to date (?)

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

- Change operation to include AsyncParse and simplify init functions (throw when asyncTransfor applied for SyncParse)
- Don't recreate the object, when nothing should be transformed - stop reallocate objects without transformations
- Add s.nested for object
- Make S.serializeToJsonString super fast
- Make operations more treeshakable by starting passing the actual operation to the initialOperation function. Or add a condition (verify performance)
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
