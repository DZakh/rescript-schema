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

v4.1

- S.variant
- Inline literals check used in S.object (Optimize S.literalVariant without transform)
- Think of the S.advancedTransform and S.advancedPreprocess destiny (Add Noop transformation)
- Make the TS code reuse rescript output instead of creating a separate bundle

Next breaking release

- S.default rework
- Make S.deprecated not wrap in option

`(S.t<'value>, ~wrapper=S.t<'value> => S.t<option<'value>>=?, unit => 'value) => S.t<'value>`

```rescript
let struct = S.string()->S.default(() => "Hello World!")

%raw(`undefined`)->S.parseWith(struct)
// Ok("Hello World!")
%raw(`"Goodbye World!"`)->S.parseWith(struct)
// Ok("Goodbye World!")

let struct = S.string()->S.default(~wrapper=S.null, () => "Hello World!")

%raw(`null`)->S.parseWith(struct)
// Ok("Hello World!")
%raw(`"Goodbye World!"`)->S.parseWith(struct)
// Ok("Goodbye World!")
```
