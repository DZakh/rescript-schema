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

- Add date refinement for string (copy zod) (?)

- S.mutateWith/S.produceWith (aka immer) (???)

- Add S.catch / S.fallback (?)

- Make the TS code reuse rescript output instead of creating a separate bundle

- Inline literals check used in S.object (Optimize S.literalVariant without transform)

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
