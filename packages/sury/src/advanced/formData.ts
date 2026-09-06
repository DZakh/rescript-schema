// `S.formData` — a form submission as a browser or `Request.formData()` hands
// it over, and the body a `fetch` call sends. An entry is a string or a
// `File`, so an object schema reads its fields through the string coercions
// the env pattern already compiles (`"42"` -> 42), a file field takes the entry
// as it is, and a repeated key is an array. Nothing reads file bytes, so both
// directions are sync.
//
// Not on the content axis (CONTENT_CODEC_SPEC.md): a form has no JSON document
// form and no format opens into one, so a link to it never has two readings,
// and a `FormData` in a JSON position has no document, the way `S.blob` has
// none. Bracket notation (`user[name]`) is deliberately out — a nested value
// travels as a `S.jsonString.with(S.to, …)` field.

import {
  anyOfTag,
  arrayTag,
  copySchema,
  inlinedValueFromString,
  instanceTag,
  initSchema,
  type Internal,
  isOptional,
  nullTag,
  pathConcat,
  setHas,
  tagFlags,
  type Tag,
  U,
  undefinedTag,
  unknown,
  unknownTag,
  type Val
} from "../base";
import {
  _var,
  B_addObjectField,
  B_dynamicScope,
  B_embed,
  B_embedInvalidInput,
  B_failWithArg,
  B_hoistDecl,
  B_invalidInputBuilder,
  B_markOutput,
  B_refine,
  B_merge,
  B_mergeWithPathPrepend,
  B_invalidOperation,
  B_next,
  B_scope,
  B_unsupportedDecode,
  B_varWithoutAllocation
} from "../builder";
import {
  arrayFactory,
  completeObjectVal,
  makeObjectVal,
  valGet
} from "../composites";
import {
  instanceDecoder,
  parse,
  unsupportedInstance
} from "../parse";
import {
 string
} from "../primitives";

const isBlobClass = (class_: unknown): boolean => {
  const blobClass = (globalThis as { Blob?: unknown }).Blob as
    | (abstract new () => unknown)
    | undefined;
  return (
    blobClass !== U &&
    class_ !== U &&
    (class_ === blobClass || (class_ as { prototype?: unknown }).prototype instanceof blobClass)
  );
};

// What a supplied entry converts to: the union's arms minus the two a blank
// field produces. Rebuilt from the union's own pieces rather than through
// unionFactory, so `S.formData` doesn't carry the union compiler for a form
// that never has an optional field.
const presentArm = (schema: Internal): Internal => {
  if (schema.type !== anyOfTag) {
    return schema;
  }
  const present: Internal[] = [];
  const has: Partial<Record<Tag, boolean>> = {};
  for (const variant of schema.anyOf!) {
    if (variant.type !== undefinedTag && variant.type !== nullTag) {
      present.push(variant);
      setHas(has, variant.type);
    }
  }
  if (present.length === 1) {
    return present[0]!;
  }
  const mut = copySchema(schema);
  mut.anyOf = present;
  mut.has = has;
  return mut;
};

// A boolean field can only be a checkbox — nothing else a browser sends is one
// — so it reads the way a checkbox submits: absent is unchecked, and a present
// entry is `"on"`, or the `"true"`/`"false"` a hidden input carries. True of a
// boolean however it is wrapped: `S.optional(S.boolean, false)` is the natural
// spelling of "checkbox, default unchecked", and its entry is still `"on"`.
// A boolean literal is one too — `S.schema(true)` is the terms-and-conditions
// box, which submits `"on"` like any other and must be checked.
const isCheckbox = (schema: Internal): boolean =>
  schema.type === anyOfTag
    ? schema.anyOf!.every((variant) => variant.type === undefinedTag || isCheckbox(variant))
    : (tagFlags[schema.type]! & 8) !== 0;

// Whether the schema states what a blank entry means. A form always submits a
// text input, so `""` is what a user leaving one alone sends — and a bare
// `S.string` is silent about whether that is a value or a missing field. These
// are the ways a schema answers: a lower length bound (`S.nonEmpty` rejects it,
// `S.minLength(0)` admits it), a literal, a named format — 30 of the 36 reject
// `""` and the rest, like `S.jsonPointer`, admit it deliberately — a pattern
// that rejects it, or a conversion whose far end decides (`S.to(S.date)`).
const decidesBlank = (schema: Internal): boolean =>
  schema.minLength !== U ||
  schema.const !== U ||
  schema.format !== U ||
  schema.to !== U ||
  (schema.pattern !== U && !schema.pattern.test(""));

// A blob takes the entry as it is, and so does `unknown`. Everything else on
// the wire is text, so it reads through a `string` stage: the entry is checked
// to be one, and the target's own decoder coerces from there, exactly as it
// does from `S.record(S.string)`.
const takesEntry = (schema: Internal): boolean =>
  schema.type === unknownTag ||
  (schema.type === instanceTag && isBlobClass(schema.class));

// A string-tagged target checks the entry is a string itself — and reads it as
// its own document where it is a format, which a `string` stage in front would
// instead escape into a JSON string value.
const fromText = (schema: Internal): Internal => {
  if (takesEntry(schema) || (tagFlags[schema.type]! & 2)) {
    return schema;
  }
  const text = copySchema(string);
  text.to = schema;
  return text;
};

// What a field's own `.to` converts from, so a reader that assembles the value
// itself can hand the parse loop something still owing that conversion.
const beforeTo = (schema: Internal): Internal => {
  if (schema.to === U) {
    return schema;
  }
  const mut = copySchema(schema);
  // `delete`, not `= U`: `unionIsTransparent` counts a schema's keys, and a
  // key left present with an undefined value stops every union flattening.
  delete mut.to;
  return mut;
};

// One entry of the list — a string or a `File` — as a schema, so the rules for
// reading one live on it rather than in a per-field inspection. `parse`
// consults a source's encoder hook once per arm of a union target, so a
// `S.union([S.boolean, S.number])` field gets the checkbox reading on its
// boolean arm and the text coercion on its number arm, which a rule applied at
// field level could never reach.
//
// Named, and instance-tagged so no text target shares its type: a same-typed
// arm would be taken as a pass-through and the hook never consulted.
const formDataField: Internal = /* @__PURE__ */ initSchema(instanceTag, instanceDecoder, (s) => {
  s.name = "form field";
});
formDataField.encoder = (input: Val, target: Internal): Val => {
  const flag = tagFlags[target.type]!;
  if (flag & 8) {
    return readCheckbox(input, target);
  }
  if (flag & 256) {
    // A union of text arms checks the entry once and dispatches on the value,
    // which is what a bare enum wants and what a per-arm check would repeat.
    // Anything else declines, so the compiler dispatches and calls this hook
    // once per arm.
    return target.anyOf!.every((variant) => tagFlags[variant.type]! & 2)
      ? asText(input, target)
      : input;
  }
  if (flag & (64 | 128)) {
    // An entry is one value, so no structure fits in it. Reported from here,
    // where the pair still names the form field — the text stage below would
    // otherwise report a `string` the schema never mentioned.
    return B_unsupportedDecode(input, formDataField, target);
  }
  // A blob takes the entry as it is, and `undefined`/`null` are the sentinels a
  // union carries for an absent one. A string-tagged target checks the entry
  // itself, and reads it as its own document where it is a format — a `string`
  // stage in front would escape it into a JSON string value instead. In all
  // three `unknown` is the source that leaves the target's own check the one
  // that runs.
  return takesEntry(target) || (flag & (2 | 16 | 32))
    ? B_refine(input, unknown, U, target)
    : asText(input, target);
};

// The entry checked to be a string, with the target's own decoder reading it
// from there.
const asText = (input: Val, target: Internal): Val =>
  B_refine(parse(B_refine(input, unknown, U, string)), string, U, target);

// A repeated key is how a form carries an array, and `getAll` is its read.
const listItem = (schema: Internal): Internal | undefined => {
  const item = schema.additionalItems;
  return schema.type === arrayTag && typeof item === "object" && !schema.items!.length
    ? item
    : U;
};

// Every field decision, taken once off the target: `present` is what a supplied
// entry converts to, and the rest say how the entry is read. They are read
// together because they interact — a `S.array(S.file)` is a list whose *item*
// takes the entry, which is not the same question as the field taking one.
type Field = {
  optional: boolean;
  // A `null` arm makes a blank entry `null`, the way an `undefined` one makes
  // it absent — both are a schema saying what an empty input means, so both
  // answer the blank question and neither is ambiguous.
  nullable: boolean;
  present: Internal;
  item: Internal | undefined;
  checkbox: boolean;
};

const classify = (schema: Internal): Field => {
  const present = presentArm(schema);
  return {
    optional: isOptional(schema),
    nullable: schema.type === anyOfTag && !!schema.has![nullTag],
    present,
    item: listItem(present),
    checkbox: isCheckbox(present),
  };
};

// The value the parse loop continues from, for a reader that assembled it
// rather than compiling one: `s` still owes the field's own `.to`, so the loop
// runs it instead of dropping it.
const assembled = (item: Val, schema: Internal, code: string, resultVar: string): Val => {
  const output = B_next(item, resultVar, beforeTo(schema), schema);
  output.v = _var;
  output.io = true;
  output.cp = code;
  return parse(B_markOutput(output, item));
};

// One arm of a possibly-absent entry, compiled on a scope of the field's own
// val and written back into `into` — the reader's result var, which is not
// always the val's own: a checkbox assembles its boolean elsewhere.
const armCode = (item: Val, source: Internal, target: Internal, into: string): string => {
  const armIn = B_scope(item);
  armIn.io = false;
  armIn.s = source;
  armIn.e = target;
  const armOut = parse(armIn);
  return B_merge(armOut) + (armOut.i === into ? "" : `${into}=${armOut.i};`);
};

// What a blank entry becomes. A `null` arm makes it `null`; an `undefined` one
// leaves the var alone, which is already absent, and runs that arm's own chain
// — where `S.optional(x, default)` keeps its default. A field with both takes
// the optional reading, since absence is the weaker claim.
const absentCode = (item: Val, field: Field, schema: Internal, into: string): string => {
  if (!field.optional) {
    return field.nullable ? `else{${into}=null}` : "";
  }
  const absent = schema.anyOf!.find((variant) => variant.type === undefinedTag)!;
  return absent.to === U ? "" : `else{${armCode(item, absent, absent, into)}}`;
};

// A possibly-absent entry, each arm converted on its own. The present one
// converts to the field's present arm rather than to the whole optional: a
// string reaching `X | undefined` would be routed through the union rules,
// which reject `string | undefined` outright and otherwise dispatch on the text
// `"undefined"`.
const readOptional = (
  item: Val,
  field: Field,
  schema: Internal,
  source: Internal,
  target: Internal,
): Val =>
  assembled(
    item,
    schema,
    `if(${item.i}!==void 0){${armCode(item, source, target, item.i)}}${absentCode(
      item,
      field,
      schema,
      item.i,
    )}`,
    item.i,
  );

// One entry read as a checkbox: `"on"` is what a checked box with no `value`
// attribute submits, the rest are the hidden-input spellings, and anything
// falsy (absent, `null`, the `""` of a box carrying an empty value) is an
// unchecked box.
const readCheckbox = (input: Val, target: Internal): Val => {
  const v = input.i;
  const outputVar = B_varWithoutAllocation(input.g);
  const output = B_next(input, outputVar, target, target);
  output.v = _var;
  output.io = true;
  output.cp = `let ${outputVar};(${outputVar}=${v}==="on"||${v}==="true"||${v}==="1")||${v}==="false"||${v}==="0"||!${v}||${B_embedInvalidInput(input, target)};`;
  return B_markOutput(output, input);
};

const readCheckboxField = (item: Val, field: Field, schema: Internal): Val => {
  const v = item.i;
  const outputVar = B_varWithoutAllocation(item.g);
  // `"on"` is the entry a checked box with no `value` attribute submits; the
  // rest are the hidden-input spellings, and match what VineJS accepts. A
  // checkbox carrying any other `value` is not a boolean — the schema names
  // that value instead of the codec guessing at it.
  const read = `(${outputVar}=${v}==="on"||${v}==="true"||${v}==="1")||${v}==="false"||${v}==="0"||`;
  const fail = B_embedInvalidInput(item, schema);
  // A literal arm is narrowed against the boolean the read produced, not
  // against the entry: "must be checked" reports the box it got, not the text
  // a browser did or didn't send. `assembled` can't emit it — its source is
  // the field's own schema, so there is nothing left for it to check.
  const narrow =
    field.present.const === U
      ? ""
      : `${outputVar}===${field.present.const}||${B_failWithArg(
          item,
          B_invalidInputBuilder(field.present)(item),
          outputVar,
        )};`;
  return assembled(
    item,
    schema,
    field.optional || field.nullable
      ? // Absent leaves the var undefined, which is the tri-state's third value
        // and what a default, or a `null` arm, converts from. Without one it
        // would be unreachable: nothing a form submits reads as `null`.
        `let ${outputVar};if(${v}){${read}${fail};${narrow}}${absentCode(
          item,
          field,
          schema,
          outputVar,
        )}`
      : // An unchecked box sends nothing, so absent is `false` — which is what
        // the comparisons already assigned by the time the guard admits it.
        `let ${outputVar};${read}!${v}||${fail};${narrow}`,
    outputVar,
  );
};

// `append` takes a string or a blob as it is; every other entry is the string
// the value converts to, through the same encoders a JSON document uses.
const appendValue = (val: Val, fdVar: string, keyText: string, inList?: boolean): string => {
  const schema = val.s;
  const tagFlag = tagFlags[schema.type]!;
  // Only a field is a checkbox. A repeated key is a list, and a list of
  // booleans is positional — dropping the false ones would lose the indices
  // the decoder reads back. (A checkbox *group* submits the values of the
  // checked boxes, which is `S.array(S.string)`.)
  if (!inList && isCheckbox(schema)) {
    // A literal settles the entry at compile time — `S.schema(true)` always
    // submits, `S.schema(false)` never does — so neither needs a guard.
    if (schema.const !== U) {
      return schema.const ? `${fdVar}.append(${keyText},"on");` : "";
    }
    // An unchecked box sends nothing, which is the whole of what the entry
    // list says about `false`, so that is what is written. A tri-state is the
    // one case the platform cannot express — absent and unchecked are the same
    // wire — so there `false` is spelled out to keep the third value apart.
    // `S.optional(S.boolean, true)` therefore cannot round-trip: its `false`
    // omits, and an absent entry is its default. That default contradicts the
    // wire, where a missing checkbox means unchecked.
    return (tagFlag & 256) && schema.has![undefinedTag]
      ? `if(${val.i}!==void 0){${fdVar}.append(${keyText},${val.i}?"on":"false")}`
      : `if(${val.i}){${fdVar}.append(${keyText},"on")}`;
  }
  const item = listItem(schema);
  if (item !== U) {
    const arrayVar = val.v();
    const iterVar = B_varWithoutAllocation(val.g);
    const raiseCountBefore = val.g.t;
    // B_dynamicScope reads the item off `e`; the recursive call picks the
    // item's own target.
    val.e = schema;
    const itemVal = B_dynamicScope(val, iterVar);
    // Built before the merge, not inside its callback: `B_mergeWithCatch` runs
    // the merge first, so a var this materializes on the item afterwards would
    // have its `let` dropped and the loop body would read an undeclared name.
    // On a scope of the item, not the item: the conversion merges its own
    // chain, and `B_mergeWithPathPrepend` below merges the item — the same val
    // in both would emit a union's dispatch `let` twice.
    const appendCode = appendValue(B_scope(itemVal), fdVar, keyText, true);
    const itemCode = B_mergeWithPathPrepend(
      itemVal,
      val,
      iterVar,
      () => appendCode,
      raiseCountBefore,
    );
    return `for(let ${iterVar}=0;${iterVar}<${arrayVar}.length;++${iterVar}){${itemCode}}`;
  }
  if ((tagFlag & 256) && (schema.has![undefinedTag] || schema.has![nullTag])) {
    // Neither absent nor null is an entry, so the whole append sits behind one
    // loose guard — `!= null` is both sentinels and shorter than testing them
    // apart.
    // Compiled on a chain detached from the field val, the way json.ts's
    // guardedJsonPiece does, so the conversion's own code lands inside it.
    const inputVar = val.v();
    const presentSchema = presentArm(schema);
    const detached = B_next(val, inputVar, presentSchema, presentSchema);
    detached.v = _var;
    detached.prev = U;
    return `if(${inputVar}!=null){${appendValue(detached, fdVar, keyText, inList)}}`;
  }
  if ((tagFlag & 2) || ((tagFlag & 8192) && isBlobClass(schema.class))) {
    return `${fdVar}.append(${keyText},${val.i});`;
  }
  if (!(tagFlag & ((4 | 8) | (32 | 1024) | (2048 | 8192) | 256))) {
    return B_unsupportedDecode(val, schema, formData);
  }
  val.io = false;
  val.e = string;
  const converted = parse(val);
  return B_merge(converted) + `${fdVar}.append(${keyText},${converted.i});`;
};

// `S.strict` means "no entries but these", which a form submission cannot
// honour: a browser appends entries of its own that no schema declared —
// `_charset_` for a hidden input of that name, one per `dirname` attribute,
// and an image button's `name.x`/`name.y`. Rejected where the pair is written
// rather than silently read as `S.strip`.
const assertNotStrict = (input: Val, schema: Internal): void => {
  // `seq` is what separates a schema someone declared from the object shape a
  // val builds as it assembles fields (`makeObjectVal`), which is always
  // `"strict"` and is not a statement about the wire. Only the declaration is
  // rejected.
  if (schema.additionalItems === "strict" && schema.seq !== U) {
    B_invalidOperation(
      input,
      `S.strict is not supported by S.formData. Use S.strip`,
    );
  }
};

const objectToFormData = (input: Val): Val => {
  assertNotStrict(input, input.s);
  const fdVar = B_varWithoutAllocation(input.g);
  const properties = input.s.properties!;
  let code = `let ${fdVar}=new ${B_embed(input, input.e.class)}();`;
  for (const key in properties) {
    const field = valGet(input, key);
    code += appendValue(field, fdVar, inlinedValueFromString(key));
  }
  const output = B_next(input, fdVar, input.e);
  output.v = _var;
  output.cp = code;
  return output;
};

const formDataToObject = (input: Val, target: Internal): Val => {
  assertNotStrict(input, target);
  const objectVal = makeObjectVal(input, target);
  const inputVar = input.v();
  const properties = target.properties!;
  for (const key in properties) {
    const schema = properties[key]!;
    const keyText = inlinedValueFromString(key);
    const field = classify(schema);
    const list = field.item !== U;
    // Both say a blank entry carries no value, so both read it away and both
    // compile their arms on their own.
    const absent = field.optional || field.nullable;
    const entry = takesEntry(field.present);

    // An empty text input submits `""`, and only an optional field reads it as
    // absent — that is the one case where the entry carries no value, and it is
    // what makes a default apply. A required field is handed `""` unchanged, so
    // the target answers for itself: `S.string` accepts it, `S.nonEmpty` and
    // `S.number` reject it in their own words. A checkbox is the exception
    // either way: a box carries no text, so an empty value is an unchecked box
    // rather than a value to report on.
    //
    // A list is `getAll`, which answers `[]` rather than `undefined`; an
    // optional one folds that empty read into absent, since a form has no other
    // way to submit an empty list.
    const readVar = B_varWithoutAllocation(input.g);
    if (list && absent) {
      // Two declarations rather than one self-referencing initializer, which
      // would read `readVar` inside its own `let` and hit the temporal dead
      // zone. Both land in the same `let`, in order.
      const allVar = B_varWithoutAllocation(input.g);
      B_hoistDecl(input, `${allVar}=${inputVar}.getAll(${keyText})`);
      B_hoistDecl(input, `${readVar}=${allVar}.length?${allVar}:void 0`);
    } else if (list) {
      B_hoistDecl(input, `${readVar}=${inputVar}.getAll(${keyText})`);
    } else if (entry) {
      // A file input with nothing chosen still submits: the HTML Standard's
      // entry list gets "a new File object with an empty name,
      // application/octet-stream as type, and an empty body". That sentinel is
      // not an upload, so it reads as absent — a required field then reports a
      // missing file rather than accepting an empty one. A string entry falls
      // through the guard untouched (`"".name` is undefined).
      // Declared on its own: the sentinel is read three times, and an
      // assignment inside the initializer would otherwise be an implicit
      // global — `new Function` is sloppy mode, so nothing would say so.
      const entryVar = B_varWithoutAllocation(input.g);
      B_hoistDecl(input, entryVar);
      B_hoistDecl(
        input,
        `${readVar}=(${entryVar}=${inputVar}.get(${keyText}))&&${entryVar}.name===""&&!${entryVar}.size?void 0:${entryVar}??void 0`,
      );
    } else {
      // A checkbox tests its entry for truth, which already covers `null` and
      // the `""` of a box carrying an empty value — so it is the one read that
      // needs no sentinel of its own.
      B_hoistDecl(
        input,
        `${readVar}=${inputVar}.get(${keyText})${
          field.checkbox ? "" : `${absent ? "||" : "??"}void 0`
        }`,
      );
    }

    // A field val the way valGet builds one: hung off the parent rather than
    // chained through `prev`, so each field's merge emits its own read and not
    // the parent's code again. Absent reads as `undefined`, the way a missing
    // object key does, so the error and the optional handling match an object's.
    // Canonical Val field order (see B_operationArg in builder.ts).
    const item: Val = {
      b: U,
      p: input,
      v: _var,
      i: readVar,
      s: list && !field.optional ? arrayFactory(unknown) : formDataField,
      io: U,
      e: schema,
      prev: U,
      f: 0,
      d: U,
      fv: U,
      cp: "",
      hd: "",
      fz: U,
      vc: U,
      u: U,
      t: true,
      path: pathConcat(input.path, [key]),
      g: input.g,
      o: U,
    };


    // A blank text input submits `""`, so a required string field that says
    // nothing about it has two equally good readings and the codec picks
    // neither.
    if (!absent && (tagFlags[field.present.type]! & 2) && !decidesBlank(field.present)) {
      B_invalidOperation(
        item,
        `say what "" means with S.nonEmpty, S.minLength(0), S.optional or S.nullable`,
        "Ambiguous",
      );
    }

    let output: Val;
    if (field.checkbox) {
      output = readCheckboxField(item, field, schema);
    } else if (list) {
      // The item decides for itself whether it takes the entry — a
      // `S.array(S.file)` is a list of entries, not of text.
      let listTarget = field.present;
      if (!takesEntry(field.item!)) {
        listTarget = copySchema(listTarget);
        listTarget.additionalItems = fromText(field.item!);
      }
      output = absent
        ? readOptional(item, field, schema, arrayFactory(unknown), listTarget)
        : ((item.e = listTarget), parse(item));
    } else if (entry || !absent) {
      // The field schema's hook takes it from here: it is consulted once per
      // union arm, so each arm reads by its own rule.
      output = parse(item);
    } else {
      // What "no entry" means is the reader's to say — the union rules have no
      // conversion into `undefined` or `null` to dispatch on.
      output = readOptional(item, field, schema, unknown, fromText(field.present));
    }
    B_addObjectField(objectVal, key, output);
  }

  return B_markOutput(completeObjectVal(objectVal), input);
};

export const formData: Internal = /* @__PURE__ */ initSchema(
  instanceTag,
  (input: Val): Val =>
    (tagFlags[input.s.type]! & 64) && typeof input.s.additionalItems === "string"
      ? objectToFormData(input)
      : instanceDecoder(input),
  (s) => {
    // Read inside the initializer, for the reason file.ts gives: a module-scope
    // member read is not something esbuild drops, and `FormData` landed in
    // Node 18.
    s.class = (globalThis as unknown as Record<string, unknown>)["FormData"];
    if (s.class === U) {
      unsupportedInstance(s, "formData");
    }
    s.encoder = (input, target) => {
      const targetTagFlag = tagFlags[target.type]!;
      return (targetTagFlag & 64) && typeof target.additionalItems === "string"
        ? formDataToObject(input, target)
        : // A union picks its variant by narrowing the form to an object it
          // isn't, so the dispatch never reaches the codec — say so here, where
          // the pair is still named.
          (targetTagFlag & 256)
          ? B_unsupportedDecode(input, input.s, target)
          : input;
    };
  },
);
