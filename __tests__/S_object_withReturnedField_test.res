open Ava

// TODO:
Failing.test("Successfully parses", t => {
  let struct = S.object(o => o->S.field("field", S.bool()))

  t->Assert.deepEqual(%raw(`{"field": true}`)->S.parseWith(struct), Ok(true), ())
})
