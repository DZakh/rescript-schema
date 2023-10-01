# Ideas draft

- Document utility functions (S.name, S.setName, S.classify, S.inline)

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

## v5.1

- Error.reason
- ppx
- stop reallocate objects without transformations
- S.matcher
- S.validateWith
- S.toJSON/S.castToJson ???
- nestedField for object
- spread for object (intersection)
- S.produce
- S.mutator

## v6

- `S.json` -> `S.json(~unsafe: bool)` to improve tree-shaking
- Add `~space` to `S.jsonString` ?
- Make S.serializeToString super fast
- Make operations more treeshakable by starting passing the actual operation to the initialOperation function. Or add a condition (verify performance)
- Remove `s.failWithError` since there's `Error.raise` 🤔
