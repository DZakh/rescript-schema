# Ideas draft

- Change:

  - S.parseWith -> S.parseAnyWith
  - S.parseOrRaiseWith -> Make it accept Js.Json.t
  - S.parseJsonWith -> S.parseWith
  - S.parseJsonStringWith -> S.parseJsonWith
  - S.serializeWith -> S.serializeAnyWith
  - S.serializeOrRaiseWith -> Make it return Js.Json.t
  - S.serializeToJsonWith -> S.serializeWith
  - S.serializeToJsonStringWith -> S.serializeJsonWith

- Document utility functions

- Clean up Caml_option.some

- Deprecate S.advancedTransform/S.asyncRefine in favor of S.transform/S.refine with updated API (???)

- Error

  - Add quotes to the path (so it's more convenient to copy-paste to console)
  - Rename toString to toText (Is it needed?)

- Add S.description

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
