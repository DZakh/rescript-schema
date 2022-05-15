open Ava

type singleFieldRecord = {foo: string}
type multipleFieldsRecord = {boo: string, zoo: string}
type user = {name: string, email: string, age: int}
type nestedRecord = {nested: singleFieldRecord}
type optionalNestedRecord = {singleFieldRecord: option<singleFieldRecord>}

test("Constructs unknown record with single field", t => {
  let value = {foo: "bar"}
  let any = %raw(`{foo: "bar"}`)

  let struct = S.record1(~fields=("foo", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

test("Constructs unknown record with multiple fields", t => {
  let value = {boo: "bar", zoo: "jee"}
  let any = %raw(`{boo: "bar", zoo: "jee"}`)

  let struct = S.record2(
    ~fields=(("boo", S.string()), ("zoo", S.string())),
    ~constructor=((boo, zoo)) => {boo: boo, zoo: zoo}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

test("Constructs unknown record with mapped field", t => {
  let value = {name: "Dmitry", email: "dzakh.dev@gmail.com", age: 21}
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct = S.record3(
    ~fields=(("Name", S.string()), ("Email", S.string()), ("Age", S.int())),
    ~constructor=((name, email, age)) => {name: name, email: email, age: age}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

test("Constructs unknown record with optional nested record when it's Some", t => {
  let value = {singleFieldRecord: Some({foo: "bar"})}
  let any = %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.option(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~constructor=foo => {foo: foo}->Ok, ()),
      ),
    ),
    ~constructor=singleFieldRecord => {singleFieldRecord: singleFieldRecord}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

test("Constructs unknown record with optional nested record when it's None", t => {
  let value = {singleFieldRecord: None}
  let any = %raw(`{}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.option(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~constructor=foo => {foo: foo}->Ok, ()),
      ),
    ),
    ~constructor=singleFieldRecord => {singleFieldRecord: singleFieldRecord}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

test("Constructs unknown record with deprecated nested record when it's Some", t => {
  let value = {singleFieldRecord: Some({foo: "bar"})}
  let any = %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.deprecated(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~constructor=foo => {foo: foo}->Ok, ()),
      ),
    ),
    ~constructor=singleFieldRecord => {singleFieldRecord: singleFieldRecord}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

test("Constructs unknown record with deprecated nested record when it's None", t => {
  let value = {singleFieldRecord: None}
  let any = %raw(`{}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.deprecated(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~constructor=foo => {foo: foo}->Ok, ()),
      ),
    ),
    ~constructor=singleFieldRecord => {singleFieldRecord: singleFieldRecord}->Ok,
    (),
  )

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

test("Constructs unknown array of records", t => {
  let value = [{foo: "bar"}, {foo: "baz"}]
  let any = %raw(`[{"MUST_BE_MAPPED":"bar"},{"MUST_BE_MAPPED":"baz"}]`)

  let struct = S.array(
    S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~constructor=foo => {foo: foo}->Ok, ()),
  )

  t->Assert.deepEqual(any->S.constructWith(struct), Ok(value), ())
})

test("Throws for a Record factory without either a constructor, or a destructor", t => {
  t->Assert.throws(() => {
    S.record1(~fields=("any", S.string()), ())->ignore
  }, ~expectations=ThrowsException.make(
    ~name="RescriptStructError",
    ~message="For a Record struct factory either a constructor, or a destructor is required",
    (),
  ), ())
})

test("Record construction fails when constructor isn't provided", t => {
  let any = %raw(`{foo: "bar"}`)

  let struct = S.record1(~fields=("foo", S.string()), ~destructor=({foo}) => foo->Ok, ())

  t->Assert.deepEqual(
    any->S.constructWith(struct),
    Error("[ReScript Struct] Failed constructing at root. Reason: Struct constructor is missing"),
    (),
  )
})

test("Nested record construction fails when constructor isn't provided", t => {
  let any = %raw(`{nested: {foo: "bar"}}`)

  let struct = S.record1(
    ~fields=("nested", S.record1(~fields=("foo", S.string()), ~destructor=({foo}) => foo->Ok, ())),
    ~constructor=nested => {nested: nested}->Ok,
    (),
  )

  t->Assert.deepEqual(
    any->S.constructWith(struct),
    Error(`[ReScript Struct] Failed constructing at ["nested"]. Reason: Struct constructor is missing`),
    (),
  )
})

test("Construction fails when user returns error in a root record constructor", t => {
  let any = %raw(`{foo: "bar"}`)

  let struct = S.record1(~fields=("foo", S.string()), ~constructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    any->S.constructWith(struct),
    Error("[ReScript Struct] Failed constructing at root. Reason: User error"),
    (),
  )
})

test("Construction fails when user returns error in a nested record constructor", t => {
  let any = %raw(`{nested: {foo: "bar"}}`)

  let struct = S.record1(
    ~fields=(
      "nested",
      S.record1(~fields=("foo", S.string()), ~constructor=_ => Error("User error"), ()),
    ),
    ~constructor=nested => {nested: nested}->Ok,
    (),
  )

  t->Assert.deepEqual(
    any->S.constructWith(struct),
    Error(`[ReScript Struct] Failed constructing at ["nested"]. Reason: User error`),
    (),
  )
})

test("Destructs unknown record with single field", t => {
  let value = {foo: "bar"}
  let any = %raw(`{foo: "bar"}`)

  let struct = S.record1(~fields=("foo", S.string()), ~destructor=({foo}) => foo->Ok, ())

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
})

test("Destructs unknown record with multiple fields", t => {
  let value = {boo: "bar", zoo: "jee"}
  let any = %raw(`{boo: "bar", zoo: "jee"}`)

  let struct = S.record2(
    ~fields=(("boo", S.string()), ("zoo", S.string())),
    ~destructor=({boo, zoo}) => (boo, zoo)->Ok,
    (),
  )

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
})

test("Destructs unknown record with mapped field", t => {
  let value = {name: "Dmitry", email: "dzakh.dev@gmail.com", age: 21}
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct = S.record3(
    ~fields=(("Name", S.string()), ("Email", S.string()), ("Age", S.int())),
    ~destructor=({name, email, age}) => (name, email, age)->Ok,
    (),
  )

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
})

test("Destructs unknown record with optional nested record when it's Some", t => {
  let value = {singleFieldRecord: Some({foo: "bar"})}
  let any = %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.option(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~destructor=({foo}) => foo->Ok, ()),
      ),
    ),
    ~destructor=({singleFieldRecord}) => singleFieldRecord->Ok,
    (),
  )

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
})

test("Destructs unknown record with optional nested record when it's None", t => {
  let value = {singleFieldRecord: None}
  let any = %raw(`{"singleFieldRecord":undefined}`)

  let struct = S.record1(
    ~fields=(
      "singleFieldRecord",
      S.option(
        S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~destructor=({foo}) => foo->Ok, ()),
      ),
    ),
    ~destructor=({singleFieldRecord}) => singleFieldRecord->Ok,
    (),
  )

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
})

test("Destructs unknown array of records", t => {
  let value = [{foo: "bar"}, {foo: "baz"}]
  let any = %raw(`[{"MUST_BE_MAPPED":"bar"},{"MUST_BE_MAPPED":"baz"}]`)

  let struct = S.array(
    S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~destructor=({foo}) => foo->Ok, ()),
  )

  t->Assert.deepEqual(value->S.destructWith(struct), Ok(any), ())
})

test("Record destruction fails when destructor isn't provided", t => {
  let value = {foo: "bar"}

  let struct = S.record1(~fields=("foo", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

  t->Assert.deepEqual(
    value->S.destructWith(struct),
    Error("[ReScript Struct] Failed destructing at root. Reason: Struct destructor is missing"),
    (),
  )
})

test("Nested record destruction fails when destructor isn't provided", t => {
  let value = {nested: {foo: "bar"}}

  let struct = S.record1(
    ~fields=(
      "nested",
      S.record1(~fields=("foo", S.string()), ~constructor=foo => {foo: foo}->Ok, ()),
    ),
    ~destructor=({nested}) => nested->Ok,
    (),
  )

  t->Assert.deepEqual(
    value->S.destructWith(struct),
    Error(`[ReScript Struct] Failed destructing at ["nested"]. Reason: Struct destructor is missing`),
    (),
  )
})

test("Destruction fails when user returns error in a root record destructor", t => {
  let value = {foo: "bar"}

  let struct = S.record1(~fields=("foo", S.string()), ~destructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    value->S.destructWith(struct),
    Error("[ReScript Struct] Failed destructing at root. Reason: User error"),
    (),
  )
})

test("Destruction fails when user returns error in a nested record destructor", t => {
  let value = {nested: {foo: "bar"}}

  let struct = S.record1(
    ~fields=(
      "nested",
      S.record1(~fields=("foo", S.string()), ~destructor=_ => Error("User error"), ()),
    ),
    ~destructor=({nested}) => nested->Ok,
    (),
  )

  t->Assert.deepEqual(
    value->S.destructWith(struct),
    Error(`[ReScript Struct] Failed destructing at ["nested"]. Reason: User error`),
    (),
  )
})

test("Constructs a record with fields mapping and destructs it back to the initial state", t => {
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct = S.record3(
    ~fields=(("Name", S.string()), ("Email", S.string()), ("Age", S.int())),
    ~constructor=((name, email, age)) => {name: name, email: email, age: age}->Ok,
    ~destructor=({name, email, age}) => (name, email, age)->Ok,
    (),
  )

  t->Assert.deepEqual(
    any->S.constructWith(struct)->Belt.Result.map(record => record->S.destructWith(struct)),
    Ok(Ok(any)),
    (),
  )
})

module ParseWith = {
  type singleFieldRecord = {foo: string}
  type optionalSingleFieldRecord = {baz: option<string>}

  test("Parses record", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(%raw(`{FOO:"bar"}`)->S.parseWith(struct), Ok({foo: "bar"}), ())
  })

  test("Parses record with optional item", t => {
    let struct = S.record1(
      ~fields=("FOO", S.option(S.string())),
      ~constructor=baz => {baz: baz}->Ok,
      (),
    )

    t->Assert.deepEqual(%raw(`{FOO:"bar"}`)->S.parseWith(struct), Ok({baz: Some("bar")}), ())
  })

  test("Parses record with optional item when it's not present", t => {
    let struct = S.record1(
      ~fields=("FOO", S.option(S.string())),
      ~constructor=baz => {baz: baz}->Ok,
      (),
    )

    t->Assert.deepEqual(%raw(`{}`)->S.parseWith(struct), Ok({baz: None}), ())
  })

  test("Fails to parse record", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      Js.Json.string("string")->S.parseWith(struct),
      Error("[ReScript Struct] Failed parsing at root. Reason: Expected Record, got String"),
      (),
    )
  })

  test("Fails to parse record item when it's not present", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      %raw(`{}`)->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at ["FOO"]. Reason: Expected String, got Option`),
      (),
    )
  })

  test("Fails to parse record item when it's not valid", t => {
    let struct = S.record1(~fields=("FOO", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

    t->Assert.deepEqual(
      %raw(`{FOO:123}`)->S.parseWith(struct),
      Error(`[ReScript Struct] Failed parsing at ["FOO"]. Reason: Expected String, got Float`),
      (),
    )
  })
}
