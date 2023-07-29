# Ideas draft

- Document utility functions (S.name, S.setName, S.classify, S.inline)

- Clean up Caml_option.some, Js_dict.get

- PPX to create structs (v5 ???)

- Add S.nullable (?)

- Add S.bigint (?)

- Github Action: Add linter checking that the generated files are up to date (?)

- Don't recreate the object, when nothing should be transformed (???)

- Update String refinements like in zod
  z.string().startsWith("https://", { message: "Must provide secure URL" });
  z.string().endsWith(".com", { message: "Only .com domains allowed" }); (?)

- Support optional fields (can have problems with serializing) (???)

- S.mutateWith/S.produceWith (aka immer) (???)

- Add S.function (?) (An alternative for external ???)

```
let trimContract: S.contract<string => string> = S.contract(s => {
  s.fn(s.arg(0, S.string))
}, ~return=S.string)
```

- Add docstrings

- Run struct factory validation checks only in dev mode

- Think of the S.advancedTransform and S.advancedPreprocess destiny

- Use S.union for S.option/S.null/S.default? (For more correct errors)

## Next breaking release

- Move S.inline to experimental or Codegen module
- Remove S.toUnknown
- Add built-in refinements to TS API
  // TODO: Update gen.ts
- Update S_Js.res to create new structs instead of mixin in the methods

## v5.1

- S.matcher
- S.validateWith
- S.toJSON/S.castToJson
- nestedField for object
- spread for object (intersection)
- S.produce
- S.mutator
- Make S.serializeToString super fast
