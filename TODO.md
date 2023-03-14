## V3.2 ideas

- Remove note about rescript version from the doc
- Document advanced utility functions

- Error

  - Add quotes to the path (so it's more convenient to copy-paste)
  - Rename toString to toText

- Metadata with refinements
- PPX to create structs
- Add nullable
- bigint struct ???
- Github Action: Add lint that the generated files are up to date. Or commit them (?)
- Don't recreate the object, when nothing should be transformed ???
- Better error message for discriminated union ??? (Support the case when there are multiple items with the same discriminants)
- Update String refinements like in zod
  z.string().startsWith("https://", { message: "Must provide secure URL" });
  z.string().endsWith(".com", { message: "Only .com domains allowed" });
- Support optional fields (can have problems with serializing) ???
- Clean up Caml_option.some
- Add date refinement for string (copy zod)
