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
let trimContract: S.contract<string => string> = S.contract(o => {
  o.fn(o->S.arg(0, S.string))
}, ~return=S.string)
```

- Add docstrings

- Update tuple (???)

```
let struct = S.tuple(o => (o.item(0, S.string), o.item(1, S.int)))
```

- Run struct factory validation checks only in dev mode

- Think of the S.advancedTransform and S.advancedPreprocess destiny

- Add input type for ts

- S.refine(~mode=[#InputAndOutput | #Input | #Output], fn) (???)

- Use S.union for S.option/S.null/S.default? (For more correct errors)

Next breaking release

- Allow passing Path string to the S.field first arg (o.nestedField)
- rename advancedFail to failWithError
- Add S.validator (use for test utils as well)
- Fix serializing performance
- Move S.inline to experimental
- Store input in the Error.t
- Remove S.toUnknown (update tuple)
- intersection / spread
- Test obj literals
