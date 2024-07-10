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

## v8

- Make S.serializeToJsonString super fast
- Rename `InvalidJsonStruct` error, since after `rescript-struct`->`rescript-schema` it became misleading
- Add S.bigint
- Add S.promise
- Check only number of fields for strict object schema when fields are not optional

## v???

- Don't recreate the object, when nothing should be transformed - stop reallocate objects without transformations
- S.validateWith
- Make `error.reason` tree-shakeable
- Add serializeToJsonString to js api
- S.toJSON/S.castToJson ???
- s.optional for object
- S.produce
- S.mutator
