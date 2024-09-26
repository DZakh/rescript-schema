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

## v9

- Remove ...OrThrow from js/ts api
- Add mode/flags instead of operation
- Simplify caching by the mode/flag
- Add S./"~experimentalReverse"
- S.transform(s => {
  s.reverse(input => input) // Or s.asyncReverse(input => Promise.resolve(input))
  input => input
  }) // or asyncTransform // Maybe format ?
- async serializing support
- Add S.unwrap
- Rename S.variant to something
- Rename serialize to convertReverse
- S.create / S.validate
- Rename S.inline to S.toRescriptCode
- Add serializeToJsonString to js api
- Fix reverse for object/tuple/variant/recursive

### Done

- Add S.compile
- Add S.bigint
- Add S.removeTypeValidation

## v10

- Make S.serializeToJsonString super fast
- Add S.promise

## v???

- Codegen type
- Codegen schema using type
- Don't recreate the object, when nothing should be transformed - stop reallocate objects without transformations
- Make `error.reason` tree-shakeable
- S.toJSON/S.castToJson ???
- s.optional for object
- S.produce
- S.mutator
- Check only number of fields for strict object schema when fields are not optional (bad idea since it's not possible to create a good error message, so we still need to have the loop)
