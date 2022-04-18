open Ava

external unsafeToUnknown: 'unknown => Js.Json.t = "%identity"

type singleFieldRecord = {foo: string}
type multipleFieldsRecord = {boo: string, zoo: string}
type user = {name: string, email: string, age: int}
type nestedRecord = {nested: singleFieldRecord}
type optionalNestedRecord = {singleFieldRecord: option<singleFieldRecord>}

test("Constructs unknown record with single field", t => {
  let record = {foo: "bar"}

  let unknownRecord = record->unsafeToUnknown
  let struct = S.record1(~fields=("foo", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

  t->Assert.deepEqual(struct->S.construct(unknownRecord), Ok(record), ())
  t->Assert.deepEqual(unknownRecord->S.constructWith(struct), Ok(record), ())
})

test("Constructs unknown record with multiple fields", t => {
  let record = {boo: "bar", zoo: "jee"}

  let unknownRecord = record->unsafeToUnknown
  let struct = S.record2(
    ~fields=(("boo", S.string()), ("zoo", S.string())),
    ~constructor=((boo, zoo)) => {boo: boo, zoo: zoo}->Ok,
    (),
  )

  t->Assert.deepEqual(struct->S.construct(unknownRecord), Ok(record), ())
  t->Assert.deepEqual(unknownRecord->S.constructWith(struct), Ok(record), ())
})

test("Constructs unknown record with mapped field", t => {
  let record = {name: "Dmitry", email: "dzakh.dev@gmail.com", age: 21}

  let unknownRecord =
    %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)->unsafeToUnknown
  let struct = S.record3(
    ~fields=(("Name", S.string()), ("Email", S.string()), ("Age", S.int())),
    ~constructor=((name, email, age)) => {name: name, email: email, age: age}->Ok,
    (),
  )

  t->Assert.deepEqual(struct->S.construct(unknownRecord), Ok(record), ())
  t->Assert.deepEqual(unknownRecord->S.constructWith(struct), Ok(record), ())
})

test("Constructs unknown record with optional nested record", t => {
  let recordWithSomeField = {singleFieldRecord: Some({foo: "bar"})}
  let recordWithNoneField = {singleFieldRecord: None}

  let unknownRecordWithSomeField =
    %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)->unsafeToUnknown
  let unknownRecordWithNoneField = %raw(`{}`)->unsafeToUnknown

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

  t->Assert.deepEqual(struct->S.construct(unknownRecordWithSomeField), Ok(recordWithSomeField), ())
  t->Assert.deepEqual(
    unknownRecordWithSomeField->S.constructWith(struct),
    Ok(recordWithSomeField),
    (),
  )
  t->Assert.deepEqual(struct->S.construct(unknownRecordWithNoneField), Ok(recordWithNoneField), ())
  t->Assert.deepEqual(
    unknownRecordWithNoneField->S.constructWith(struct),
    Ok(recordWithNoneField),
    (),
  )
})

test("Constructs unknown record with deprecated nested record", t => {
  let recordWithSomeField = {singleFieldRecord: Some({foo: "bar"})}
  let recordWithNoneField = {singleFieldRecord: None}

  let unknownRecordWithSomeField =
    %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)->unsafeToUnknown
  let unknownRecordWithNoneField = %raw(`{}`)->unsafeToUnknown

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

  t->Assert.deepEqual(struct->S.construct(unknownRecordWithSomeField), Ok(recordWithSomeField), ())
  t->Assert.deepEqual(
    unknownRecordWithSomeField->S.constructWith(struct),
    Ok(recordWithSomeField),
    (),
  )
  t->Assert.deepEqual(struct->S.construct(unknownRecordWithNoneField), Ok(recordWithNoneField), ())
  t->Assert.deepEqual(
    unknownRecordWithNoneField->S.constructWith(struct),
    Ok(recordWithNoneField),
    (),
  )
})

test("Constructs unknown array of records", t => {
  let arrayOfRecords = [{foo: "bar"}, {foo: "baz"}]

  let unknownArrayOfRecords =
    %raw(`[{"MUST_BE_MAPPED":"bar"},{"MUST_BE_MAPPED":"baz"}]`)->unsafeToUnknown
  let arrayOfRecordsStruct = S.array(
    S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~constructor=foo => {foo: foo}->Ok, ()),
  )

  t->Assert.deepEqual(
    arrayOfRecordsStruct->S.construct(unknownArrayOfRecords),
    Ok(arrayOfRecords),
    (),
  )
  t->Assert.deepEqual(
    unknownArrayOfRecords->S.constructWith(arrayOfRecordsStruct),
    Ok(arrayOfRecords),
    (),
  )
})

test("Throws for a Record factory without either a constructor, or a destructor", t => {
  t->Assert.throws(() => {
    S.record1(~fields=("any", S.string()), ())->ignore
  }, ~expectations=ThrowsException.make(
    ~message="For a Record struct either a constructor, or a destructor is required",
    (),
  ), ())
})

test("Record construction fails when constructor isn't provided", t => {
  let record = {foo: "bar"}

  let unknownRecord = record->unsafeToUnknown
  let struct = S.record1(~fields=("foo", S.string()), ~destructor=({foo}) => foo->Ok, ())

  t->Assert.deepEqual(
    struct->S.construct(unknownRecord),
    Error("Struct missing constructor at root"),
    (),
  )
  t->Assert.deepEqual(
    unknownRecord->S.constructWith(struct),
    Error("Struct missing constructor at root"),
    (),
  )
})

test("Nested record construction fails when constructor isn't provided", t => {
  let record = {nested: {foo: "bar"}}

  let unknownRecord = record->unsafeToUnknown
  let struct = S.record1(
    ~fields=("nested", S.record1(~fields=("foo", S.string()), ~destructor=({foo}) => foo->Ok, ())),
    ~constructor=nested => {nested: nested}->Ok,
    (),
  )

  t->Assert.deepEqual(
    struct->S.construct(unknownRecord),
    Error(`Struct missing constructor at ."nested"`),
    (),
  )
  t->Assert.deepEqual(
    unknownRecord->S.constructWith(struct),
    Error(`Struct missing constructor at ."nested"`),
    (),
  )
})

test("Construction fails when user returns error in a root record constructor", t => {
  let record = {foo: "bar"}

  let unknownRecord = record->unsafeToUnknown
  let struct = S.record1(~fields=("foo", S.string()), ~constructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    struct->S.construct(unknownRecord),
    Error("Struct construction failed at root. Reason: User error"),
    (),
  )
  t->Assert.deepEqual(
    unknownRecord->S.constructWith(struct),
    Error("Struct construction failed at root. Reason: User error"),
    (),
  )
})

test("Construction fails when user returns error in a nested record constructor", t => {
  let record = {nested: {foo: "bar"}}

  let unknownRecord = record->unsafeToUnknown
  let struct = S.record1(
    ~fields=(
      "nested",
      S.record1(~fields=("foo", S.string()), ~constructor=_ => Error("User error"), ()),
    ),
    ~constructor=nested => {nested: nested}->Ok,
    (),
  )

  t->Assert.deepEqual(
    struct->S.construct(unknownRecord),
    Error(`Struct construction failed at ."nested". Reason: User error`),
    (),
  )
  t->Assert.deepEqual(
    unknownRecord->S.constructWith(struct),
    Error(`Struct construction failed at ."nested". Reason: User error`),
    (),
  )
})

test("Destructs unknown record with single field", t => {
  let record = {foo: "bar"}

  let unknownRecord = record->unsafeToUnknown
  let struct = S.record1(~fields=("foo", S.string()), ~destructor=({foo}) => foo->Ok, ())

  t->Assert.deepEqual(struct->S.destruct(record), Ok(unknownRecord), ())
  t->Assert.deepEqual(record->S.destructWith(struct), Ok(unknownRecord), ())
})

test("Destructs unknown record with multiple fields", t => {
  let record = {boo: "bar", zoo: "jee"}

  let unknownRecord = record->unsafeToUnknown
  let struct = S.record2(
    ~fields=(("boo", S.string()), ("zoo", S.string())),
    ~destructor=({boo, zoo}) => (boo, zoo)->Ok,
    (),
  )

  t->Assert.deepEqual(struct->S.destruct(record), Ok(unknownRecord), ())
  t->Assert.deepEqual(record->S.destructWith(struct), Ok(unknownRecord), ())
})

test("Destructs unknown record with mapped field", t => {
  let record = {name: "Dmitry", email: "dzakh.dev@gmail.com", age: 21}

  let unknownRecord =
    %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)->unsafeToUnknown
  let struct = S.record3(
    ~fields=(("Name", S.string()), ("Email", S.string()), ("Age", S.int())),
    ~destructor=({name, email, age}) => (name, email, age)->Ok,
    (),
  )

  t->Assert.deepEqual(struct->S.destruct(record), Ok(unknownRecord), ())
  t->Assert.deepEqual(record->S.destructWith(struct), Ok(unknownRecord), ())
})

test("Destructs unknown record with optional nested record", t => {
  let recordWithSomeField = {singleFieldRecord: Some({foo: "bar"})}
  let recordWithNoneField = {singleFieldRecord: None}

  let unknownRecordWithSomeField =
    %raw(`{"singleFieldRecord":{"MUST_BE_MAPPED":"bar"}}`)->unsafeToUnknown
  let unknownRecordWithNoneField = %raw(`{"singleFieldRecord":undefined}`)->unsafeToUnknown

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

  t->Assert.deepEqual(struct->S.destruct(recordWithSomeField), Ok(unknownRecordWithSomeField), ())
  t->Assert.deepEqual(
    recordWithSomeField->S.destructWith(struct),
    Ok(unknownRecordWithSomeField),
    (),
  )
  t->Assert.deepEqual(struct->S.destruct(recordWithNoneField), Ok(unknownRecordWithNoneField), ())
  t->Assert.deepEqual(
    recordWithNoneField->S.destructWith(struct),
    Ok(unknownRecordWithNoneField),
    (),
  )
})

test("Destructs unknown array of records", t => {
  let arrayOfRecords = [{foo: "bar"}, {foo: "baz"}]

  let unknownArrayOfRecords =
    %raw(`[{"MUST_BE_MAPPED":"bar"},{"MUST_BE_MAPPED":"baz"}]`)->unsafeToUnknown
  let arrayOfRecordsStruct = S.array(
    S.record1(~fields=("MUST_BE_MAPPED", S.string()), ~destructor=({foo}) => foo->Ok, ()),
  )

  t->Assert.deepEqual(
    arrayOfRecordsStruct->S.destruct(arrayOfRecords),
    Ok(unknownArrayOfRecords),
    (),
  )
  t->Assert.deepEqual(
    arrayOfRecords->S.destructWith(arrayOfRecordsStruct),
    Ok(unknownArrayOfRecords),
    (),
  )
})

test("Record destruction fails when destructor isn't provided", t => {
  let record = {foo: "bar"}

  let struct = S.record1(~fields=("foo", S.string()), ~constructor=foo => {foo: foo}->Ok, ())

  t->Assert.deepEqual(struct->S.destruct(record), Error("Struct missing destructor at root"), ())
  t->Assert.deepEqual(
    record->S.destructWith(struct),
    Error("Struct missing destructor at root"),
    (),
  )
})

test("Nested record destruction fails when destructor isn't provided", t => {
  let record = {nested: {foo: "bar"}}

  let struct = S.record1(
    ~fields=(
      "nested",
      S.record1(~fields=("foo", S.string()), ~constructor=foo => {foo: foo}->Ok, ()),
    ),
    ~destructor=({nested}) => nested->Ok,
    (),
  )

  t->Assert.deepEqual(
    struct->S.destruct(record),
    Error(`Struct missing destructor at ."nested"`),
    (),
  )
  t->Assert.deepEqual(
    record->S.destructWith(struct),
    Error(`Struct missing destructor at ."nested"`),
    (),
  )
})

test("Destruction fails when user returns error in a root record destructor", t => {
  let record = {foo: "bar"}

  let struct = S.record1(~fields=("foo", S.string()), ~destructor=_ => Error("User error"), ())

  t->Assert.deepEqual(
    struct->S.destruct(record),
    Error("Struct destruction failed at root. Reason: User error"),
    (),
  )
  t->Assert.deepEqual(
    record->S.destructWith(struct),
    Error("Struct destruction failed at root. Reason: User error"),
    (),
  )
})

test("Destruction fails when user returns error in a nested record destructor", t => {
  let record = {nested: {foo: "bar"}}

  let struct = S.record1(
    ~fields=(
      "nested",
      S.record1(~fields=("foo", S.string()), ~destructor=_ => Error("User error"), ()),
    ),
    ~destructor=({nested}) => nested->Ok,
    (),
  )

  t->Assert.deepEqual(
    struct->S.destruct(record),
    Error(`Struct destruction failed at ."nested". Reason: User error`),
    (),
  )
  t->Assert.deepEqual(
    record->S.destructWith(struct),
    Error(`Struct destruction failed at ."nested". Reason: User error`),
    (),
  )
})

test("Constructs a record with fields mapping and destructs it back to the initial state", t => {
  let unknownRecord =
    %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)->unsafeToUnknown
  let struct = S.record3(
    ~fields=(("Name", S.string()), ("Email", S.string()), ("Age", S.int())),
    ~constructor=((name, email, age)) => {name: name, email: email, age: age}->Ok,
    ~destructor=({name, email, age}) => (name, email, age)->Ok,
    (),
  )

  t->Assert.deepEqual(
    struct->S.construct(unknownRecord)->Belt.Result.map(record => struct->S.destruct(record)),
    Ok(Ok(unknownRecord)),
    (),
  )
})
