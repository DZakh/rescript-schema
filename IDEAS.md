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

- Use internal transform for trim

## v10

- Rename S.to to S.reshape
- Change S.classify to something like S.input/S.output
- Add refinement info to the tagged type
- Add S.string->S.coerce(S.int) to coerce string to int and other types
- Add S.codegen
- Add schema input to the error ??? What about build errors?
- Remove Literal.parse in favor of S.literal and make it create Object/Tuple schema instead of Literal(Object)
- S.transform(s => {
  s.reverse(input => input) // Or s.asyncReverse(input => Promise.resolve(input))
  input => input
  }) // or asyncTransform // Maybe format ?
- async serializing support
- S.create / S.validate
- Make S.serializeToJsonString super fast
- Add S.promise
- s.optional for object

## v???

- Rename S.inline to S.toRescriptCode + Codegen type + Codegen schema using type
- Make `error.reason` tree-shakeable
- S.toJSON/S.castToJson ???
- S.produce
- S.mutator
- Check only number of fields for strict object schema when fields are not optional (bad idea since it's not possible to create a good error message, so we still need to have the loop)
