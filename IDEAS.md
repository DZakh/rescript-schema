# Ideas draft

- Change:

  - S.parseWith -> S.parseAnyWith
  - S.parseOrRaiseWith -> Make it accept Js.Json.t
  - S.parseJsonWith -> S.parseWith
  - S.parseJsonStringWith -> S.parseJsonWith
  - S.serializeWith -> S.serializeToUnknownWith
  - S.serializeOrRaiseWith -> Make it return Js.Json.t
  - S.serializeToJsonWith -> S.serializeWith
  - S.serializeToJsonStringWith -> S.serializeToJsonWith

- Document utility functions (S.name, S.classify, S.inline)

- Clean up Caml_option.some, Js_dict.get

- Deprecate S.advancedTransform/S.asyncRefine in favor of S.transform/S.refine with updated API (???)

- Add S.inline

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

- Rename S.trimmed -> S.trim / S.defaulted -> S.default

- Add S.catch / S.fallback (?)

- Make the TS code reuse rescript output instead of creating a separate bundle

- Inline literals check used in S.object

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

- Use better variant names for unions in S.inline

- Add S.unit
