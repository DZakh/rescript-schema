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

## v5.2

- S.matcher
- ppx

## v5.3

- stop reallocate objects without transformations
- Add `~space` to `S.jsonString` ?
- Make S.serializeToString super fast
- Add serialiseToString to js api
- Make operations more treeshakable by starting passing the actual operation to the initialOperation function. Or add a condition (verify performance)
- S.validateWith

## v6

- `S.json` -> `S.json(~unsafe: bool)` to improve tree-shaking
- Remove `s.failWithError` since there's `Error.raise` 🤔
- Make `error.reason` tree-shakeable
- Update `Literal` `tagged` to include `text`, `value` and `kind`. So it's more convinient and smaller bundle-size
- Turn `String.email` -> `email`, `String.min` -> `stringMin` for tree-shaking

## v???

- S.toJSON/S.castToJson ???
- nestedField for object
- s.spread for object
- S.produce
- S.mutator
