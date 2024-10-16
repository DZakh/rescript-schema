open Ava

test("Successfully parses", t => {
  let schema = S.string
  let schemaWithoutTypeValidation = schema->S.removeTypeValidation

  t->Assert.deepEqual(
    1->S.parseAnyWith(schema),
    Error(
      S.Error.make(
        ~code=S.InvalidType({
          expected: schema->S.toUnknown,
          received: %raw(`1`),
        }),
        ~flag=S.Flag.typeValidation,
        ~path=S.Path.empty,
      ),
    ),
    (),
  )
  t->Assert.deepEqual(1->S.parseAnyWith(schemaWithoutTypeValidation), Ok(%raw(`1`)), ())
})
