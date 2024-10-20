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

- Remove ...OrThrow/orRaise
- Add S.compile to Js/ts api
- S.transform(s => {
  s.reverse(input => input) // Or s.asyncReverse(input => Promise.resolve(input))
  input => input
  }) // or asyncTransform // Maybe format ?
- async serializing support
- S.create / S.validate
- Rename S.inline to S.toRescriptCode
- Fix reverse for object/tuple/to/recursive/schema
- Rename disableNanNumberCheck to use validation
- Add tag for BigInt
- Add flatten to ts api
- Get rid of Caml_js_exceptions.internalToOCamlException
- Add testWith
- Use type args for S.compile - tweet why it didn't work
- Change asyncParser from () => () => promise to () => promise
- Add schema input to the error ??? What about build errors?
- Get rid of S.literal in Js/ts API
- Use Ts types for schema names
  // FIXME: Return back s.flatten support for schemas created with S.schema

### Done

- Removed deprecated APIs, check S.resi diff, S.d.ts and RescriptSchema.gen.ts

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
