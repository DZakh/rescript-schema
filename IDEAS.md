# Ideas draft

- Document utility functions (S.name, S.classify, S.inline)

- Clean up Caml_option.some, Js_dict.get

- PPX to create structs (v5 ???)

- Add S.nullable (?)

- Add S.bigint (?)

- Github Action: Add linter checking that the generated files are up to date (?)

- Don't recreate the object, when nothing should be transformed (???)

- Better error message for discriminated union (??) (Support the case when there are multiple items with the same discriminants)

- Update String refinements like in zod
  z.string().startsWith("https://", { message: "Must provide secure URL" });
  z.string().endsWith(".com", { message: "Only .com domains allowed" }); (?)

- Support optional fields (can have problems with serializing) (???)

- S.mutateWith/S.produceWith (aka immer) (???)

- Make the TS code reuse rescript output instead of creating a separate bundle

- Add S.function (?) (An alternative for external ???)

```
let trimContract: S.contract<string => string> = S.contract(o => {
  o.fn(o->S.arg(0, S.string()))
}, ~return=S.string())
```

- Add docstrings

- Update tuple (???)

```
let struct = S.tuple(o => (o->S.item(0, S.string()), o->S.item(1, S.int())))
```

- Run struct factory validation checks only in dev mode

- Use instanceof Error for internal error (???)

- Think of the S.advancedTransform and S.advancedPreprocess destiny

v4.1

- S.variant
- Inline literals check used in S.object (Optimize S.literalVariant without transform)
- S.Int.multipleOf
- S.Float.multipleOf
- Add S.catch / S.fallback (?)
- Add date refinement for string (copy zod) (?)
