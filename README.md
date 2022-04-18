# ReScript Struct

A simple and composable way to describe relationship between JavaScript and ReScript structures.

## Installation

```sh
npm install rescript-struct
```

Then add `rescript-struct` to `bs-dependencies` in your `bsconfig.json`:

```diff
{
  ...
+ "bs-dependencies": ["rescript-struct"]
}
```

## Usage

ReScript Struct allows you to define the shape of data. You can use the shape to serialize, validate or do whatever you need with a neat integration system.

### Libraries using ReScript Struct

- [ReScript JSON Schema](https://github.com/dzakh-packages/rescript-json-schema) - Typesafe JSON schema for ReScript

### Example

```rescript
type author = {
  id: float,
  tags: array<string>,
  isAproved: bool,
  deprecatedAge: option<int>
}

let authorStruct: S.t<author> = S.record4(
  ~fields=(
    ("Id", S.float()),
    ("Tags", S.array(S.string())),
    ("IsApproved", S.option(S.coercedInt(~constructor=int =>
          switch int {
          | 1 => true
          | _ => false
          }->Ok
        , ()))->S.default(false)),
    ("Age", S.deprecated(~message="A useful explanation", S.int())),
  ),
  ~constructor=((id, tags, isAproved, deprecatedAge)) =>
    {id: id, tags: tags, isAproved: isAproved, deprecatedAge: deprecatedAge}->Ok,
  (),
)

let constructResult1: result<author, string> = %raw(`{
  "Id": 1,
  "Tags": [],
  "IsApproved": 1,
  "Age": 12,
}`)->S.constructWith(authorStruct)
// Equal to:
// Ok({
//   id: 1.,
//   tags: [],
//   isAproved: true,
//   deprecatedAge: Some(12),
// })

let constructResult2: result<author, string> = %raw(`{
  "Id": 1,
  "Tags": ["Loved"],
}`)->S.constructWith(authorStruct)
// Equal to:
// Ok({
//   id: 1.,
//   tags: ["Loved"],
//   isAproved: false,
//   deprecatedAge: None,
// })
```
