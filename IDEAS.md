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

## v9

- Add S.compile to Js/ts api
- Rename disableNanNumberCheck to use validation
- Add flatten to ts api
- Add testWith
- Add reverseConvert to js/ts api
- Change asyncParser from () => () => promise to () => promise
- Add schema input to the error ??? What about build errors?
- Get rid of S.literal in Js/ts API and S.tuple shorthand
- Rename S.Object.strict to S.strict (the same for strip)
- Fix unknownKeys for nested S.schema

### Done

- Removed deprecated APIs, check S.resi diff, S.d.ts and RescriptSchema.gen.ts
- Tuples and Objects created by S.schema don't recreate the input if there are no transformed fields
- Async for reversed object ???
- S.compile changed some arg variant names and now supports reverse flag
- Removed validation for multiple registered fields that they have the same data
- Ability to spread any schema in S.object
- Replace s.nestedField with S.nested
- Rename Js integer to int32. Remove integerMax/integerMin
- Use Js friendly names for schema names
- Add tag for bigint schema

## v10

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
