// `S.formData` - a form submission as a browser or `Request.formData()` hands
// it over, and the body a `fetch` call sends. An entry is a string or a
// `File`, so an object schema reads its fields through the string coercions
// the env pattern already compiles (`"42"` -> 42), a file field takes the entry
// as it is, and a repeated key is an array. Nothing reads file bytes, so both
// directions are sync.
//
// Not on the content axis (CONTENT_CODEC_SPEC.md): a form has no JSON document
// form and no format opens into one, so a link to it never has two readings,
// and a `FormData` in a JSON position has no document, the way `S.blob` has
// none. Bracket notation (`user[name]`) is deliberately out - a nested value
// travels as a `S.jsonString.with(S.to, …)` field.

import {
  anyOfTag,
  arrayTag,
  copySchema,
  inlinedValueFromString,
  instanceTag,
  initSchema,
  inputExpression,
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
  B_hoistDecl,
  B_markOutput,
  B_refine,
  B_merge,
  B_mergeWithPathPrepend,
  B_invalidOperation,
  B_next,
  B_nextConst,
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
 bool,
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
  if (present.length < 2) {
    // Nothing left to supply means the field is never on the wire, and it is
    // its own present arm: an entry where none belongs is then reported
    // against the sentinels the schema does declare.
    return present[0] || schema;
  }
  const mut = copySchema(schema);
  mut.anyOf = present;
  mut.has = has;
  return mut;
};

// A boolean field can only be a checkbox - nothing else a browser sends is one
// - so it reads the way a checkbox submits: absent is unchecked, and a present
// entry is `"on"`, or the `"true"`/`"false"` a hidden input carries. True of a
// boolean however it is wrapped: `S.optional(S.boolean, false)` is the natural
// spelling of "checkbox, default unchecked", and its entry is still `"on"`.
// A boolean literal is one too - `S.schema(true)` is the terms-and-conditions
// box, which submits `"on"` like any other and must be checked.
const isCheckbox = (schema: Internal): boolean =>
  schema.type === anyOfTag
    ? schema.anyOf!.some((variant) => tagFlags[variant.type]! & 8) &&
      schema.anyOf!.every(
        (variant) =>
          variant.type === undefinedTag || variant.type === nullTag || isCheckbox(variant),
      )
    : (tagFlags[schema.type]! & 8) !== 0;

// Whether the target states what a blank entry means. A form always submits a
// text input, so `""` is what a user leaving one alone sends - and a bare
// string is silent about whether that is a value or a missing field. Every
// other type says - a number rejects `""`, a checkbox reads it as unchecked -
// and so does a string with a lower length bound (`S.nonEmpty` rejects it,
// `S.minLength(0)` admits it), a literal, a named format, or a pattern that
// rejects it. A bare string that hands its text on to another string, the way
// `S.trim` does, leaves the question to that one; each arm of a union answers
// for itself.
const decidesBlank = (schema: Internal): boolean => {
  const flag = tagFlags[schema.type]!;
  return flag & 256
    ? schema.anyOf!.every(decidesBlank)
    : !(flag & 2) ||
        schema.minLength !== U ||
        schema.const !== U ||
        schema.format !== U ||
        (schema.pattern !== U && !schema.pattern.test("")) ||
        (schema.to !== U && decidesBlank(schema.to));
};

// Whether the schema names `""` as a value of its own - `S.minLength(0)`, the
// literal, or an arm that is either - so a blank entry is handed to it rather
// than read as absent.
const admitsBlank = (schema: Internal): boolean =>
  schema.minLength === 0 ||
  schema.const === "" ||
  (schema.type === anyOfTag && schema.anyOf!.some(admitsBlank));

const isNullable = (schema: Internal): boolean =>
  schema.type === nullTag || (schema.type === anyOfTag && !!schema.has![nullTag]);

// Whether the schema says what "no entry" means. It is the one question both
// directions ask of a field - the decode has somewhere to put a missing key,
// and the encode has a value it must not write - and the one that makes an
// item unfit for a list, where every position is an entry.
const isAbsent = (schema: Internal): boolean => isOptional(schema) || isNullable(schema);

// A blob takes the entry as it is, and so does `unknown`. Everything else on
// the wire is text, so it reads through a `string` stage: the entry is checked
// to be one, and the target's own decoder coerces from there, exactly as it
// does from `S.record(S.string)`.
const takesEntry = (schema: Internal): boolean =>
  schema.type === unknownTag ||
  (schema.type === instanceTag && isBlobClass(schema.class));

const isList = (schema: Internal): boolean => schema.type === arrayTag;

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

// The entry list as a lookup, in one pass. A key that repeats holds an array,
// which is what lets a field declared as one value report the two it got
// (`Expected string, received ["a", "b"]`) instead of silently taking the
// first - `get` answers the first and says nothing. A `Map`, not an object:
// the keys are whatever the client sent, and `__proto__` is one of them.
const readEntries = (formData: FormData): Map<string, unknown> => {
  const entries = new Map<string, unknown>();
  for (const [key, value] of formData as unknown as Iterable<[string, unknown]>) {
    // A file input with nothing chosen still submits: the HTML Standard's
    // entry list gets "a new File object with an empty name,
    // application/octet-stream as type, and an empty body". That sentinel is
    // not an upload, so no field sees it - a required one reports a missing
    // file, a list reads without it.
    if (typeof value !== "string" && (value as File).name === "" && !(value as File).size) {
      continue;
    }
    const prev = entries.get(key);
    prev === U
      ? entries.set(key, value)
      : Array.isArray(prev)
        ? prev.push(value)
        : entries.set(key, [prev, value]);
  }
  return entries;
};

// A key's entries as a list: one entry is a one-item list and none is an
// empty one, since a form has no other way to send either.
const asList = (value: unknown): unknown[] =>
  value === U ? [] : Array.isArray(value) ? value : [value];

// One entry of the form - a string or a `File` - as a schema, so the rules for
// reading one live on it rather than in a per-field inspection. `parse`
// consults a source's encoder hook once per arm of a union target, so a
// `S.union([S.boolean, S.number])` field gets the checkbox reading on its
// boolean arm and the text coercion on its number arm, which a rule applied at
// field level could never reach.
//
// Two of them, differing in what a blank entry means to the target. A field's
// own entry may be blank, and a target that does not say what that means is
// ambiguous. An entry a blank was read away from - the field has an absent
// reading and hands `""` to it - or one that stands at a position in a list,
// where there is no absent to read it as, holds a value and asks nothing.
//
// Named, and instance-tagged so no text target shares its type: a same-typed
// arm would be taken as a pass-through and the hook never consulted.
const entrySchema = (blank: boolean): Internal =>
  initSchema(instanceTag, instanceDecoder, (s) => {
    s.name = "form field";
    // Set inside the initializer: a property write at module scope is a
    // statement esbuild keeps, and every bundle would carry the codec.
    s.encoder = (input: Val, target: Internal): Val => {
      if (blank && !decidesBlank(target)) {
        B_invalidOperation(
          input,
          `Ambiguous "" for ${inputExpression(target)}. Should a blank input be rejected, kept, or read as absent? Choose with S.nonEmpty, S.minLength(0), or S.optional`,
        );
      }
      const flag = tagFlags[target.type]!;
      if (flag & 8) {
        return readCheckbox(input, target);
      }
      if (flag & 256) {
        // A union of text arms checks the entry once and dispatches on the
        // value, which is what a bare enum wants and what a per-arm check
        // would repeat.
        if (target.anyOf!.every((variant) => tagFlags[variant.type]! & 2)) {
          return asText(input, target);
        }
        // Anything else is dispatched by the compiler, which hands each arm a
        // narrow that carries no more than its runtime type. The blank
        // question was answered here for the whole union, so the arms are
        // asked as values.
        const output = B_next(input, input.i, formDataValue, target);
        output.v = _var;
        return output;
      }
      if (flag & (64 | 128 | 512)) {
        // An entry is one value, so no structure fits in it. Reported from
        // here, where the pair still names the form field - the text stage
        // below would otherwise report a `string` the schema never mentioned.
        return B_unsupportedDecode(input, s, target);
      }
      // A blob takes the entry as it is, and `undefined`/`null` are the
      // sentinels a union carries for an absent one. A string-tagged target
      // checks the entry itself, and reads it as its own document where it is
      // a format - a `string` stage in front would escape it into a JSON
      // string value instead. In all three `unknown` is the source that leaves
      // the target's own check the one that runs.
      return takesEntry(target) || (flag & (2 | 16 | 32))
        ? B_refine(input, unknown, U, target)
        : asText(input, target);
    };
  });
const formDataEntry: Internal = /* @__PURE__ */ entrySchema(true);
const formDataValue: Internal = /* @__PURE__ */ entrySchema(false);
const formDataList: Internal = /* @__PURE__ */ arrayFactory(formDataValue);

// The entry checked to be a string, with the target's own decoder reading it
// from there. The check names the target: `Expected number, received
// undefined` is the field's own vocabulary, and `string` is not.
const asText = (input: Val, target: Internal): Val => {
  const output = B_next(input, input.i, string, target);
  output.v = _var;
  output.cp = `typeof ${input.i}==="string"||${B_embedInvalidInput(input, target)};`;
  return output;
};

// One entry read as a checkbox: `"on"` is what a checked box with no `value`
// attribute submits, `"true"`/`"false"` is what a hidden input carries.
// Anything falsy - absent, `null`, the `""` of a box carrying an empty value -
// is an unchecked box, so a required boolean needs no absent reading of its
// own. A checkbox carrying any other `value` is not a boolean: the schema
// names that value instead of the codec guessing at it.
const readCheckbox = (input: Val, target: Internal): Val => {
  const v = input.i;
  if (target.const !== U) {
    // A literal is settled by the entry itself, so the failure names what the
    // browser sent - a box that must be ticked reports `received undefined`,
    // not a `false` nothing submitted.
    const output = B_nextConst(input, target);
    output.cp = `${target.const ? `${v}==="on"||${v}==="true"` : `${v}==="false"||!${v}`}||${B_embedInvalidInput(input, target)};`;
    return output;
  }
  // Into a var of its own, not the entry's: a check the target adds after this
  // fails on the boolean, and the next arm of a union then reads the entry as
  // the browser sent it.
  const out = B_varWithoutAllocation(input.g);
  const output = B_next(input, out, bool, target);
  output.v = _var;
  output.cp = `let ${out}=${v}==="on"||${v}==="true"||(${v}==="false"||!${v}?false:${B_embedInvalidInput(input, target)});`;
  return output;
};

// Every schema a list's items can take: the rest item, the fixed slots, or both.
const listItems = (schema: Internal): Internal[] => {
  const rest = schema.additionalItems;
  return schema.items!.concat(typeof rest === "object" ? [rest] : []);
};

// What a repeated key can carry, asked by both directions: it is read and
// written by position, so every item is exactly one entry.
const assertListItems = (val: Val, schema: Internal): void => {
  const unsupported = (why: string): never =>
    B_invalidOperation(val, `Can't decode form field -> ${inputExpression(schema)}. ${why}`);
  for (const item of listItems(schema)) {
    if (isCheckbox(item)) {
      // A checkbox is a whole field: a group of them submits the *value* of
      // each checked box, never `"on"` per position.
      unsupported(`A checkbox group sends the value of each checked box, so read it as string[]`);
    }
    if (isAbsent(item)) {
      // An item with no entry would shift every item after it rather than
      // leave a hole.
      unsupported(`A repeated key is positional, so every item needs an entry`);
    }
    if (isList(item)) {
      unsupported(`A repeated key is flat`);
    }
  }
};

// One arm of a possibly-absent entry, compiled on a scope of the field's own
// val and left in that val's var, which is where the other arm writes too.
const armCode = (item: Val, source: Internal, target: Internal): string => {
  const armIn = B_scope(item);
  armIn.io = false;
  armIn.s = source;
  armIn.e = target;
  const armOut = parse(armIn);
  // A promise left in the var is the field's to await, which `readWrapped`
  // reads off the field val.
  item.f |= armOut.f & 1;
  return B_merge(armOut) + (armOut.i === item.i ? "" : `${item.i}=${armOut.i};`);
};

// The arm no entry reads as. A field with both takes the optional reading,
// since absence is the weaker claim.
const absentArm = (schema: Internal): Internal =>
  schema.anyOf?.find(
    (variant) => variant.type === (isOptional(schema) ? undefinedTag : nullTag),
  ) || schema;

// Whether the absent arm writes into the var: `null`, or the default its own
// chain carries. An `undefined` arm without one leaves the var alone, which
// is already absent.
const absentWrites = (schema: Internal): boolean =>
  absentArm(schema).to !== U || !isOptional(schema);

// What runs on no entry: the absent arm's own chain, `null`, or nothing.
const absentCode = (item: Val, schema: Internal): string => {
  const absent = absentArm(schema);
  return absent.to !== U
    ? armCode(item, absent, absent)
    : isOptional(schema)
      ? ""
      : `${item.i}=null`;
};

// A field with a wrapper, each arm converted on its own. The present one
// converts to the field's present arm rather than to the whole optional: a
// string reaching `X | undefined` would be routed through the union rules,
// which reject `string | undefined` outright and otherwise dispatch on the text
// `"undefined"`. The result continues from a val whose schema still owes the
// wrapper's own `.to`, so the loop runs it instead of dropping it.
//
// `folds` says whether a blank entry was read as absent, which is what lets
// the var's own truth tell an entry from none. A list is never absent - no
// entries is the empty list - and has no `folds` to speak of.
const readWrapped = (
  item: Val,
  schema: Internal,
  present: Internal,
  folds: boolean | undefined,
): Val => {
  const v = item.i;
  const presentCode = armCode(item, item.s, present);
  let code = presentCode;
  if (folds !== U) {
    const absent = absentCode(item, schema);
    // An arm with nothing to run leaves no empty block behind.
    code = presentCode
      ? `if(${folds ? v : `${v}!==void 0`}){${presentCode}}${absent && `else{${absent}}`}`
      : absent
        ? `if(${folds ? `!${v}` : `${v}===void 0`}){${absent}}`
        : "";
  }
  const output = B_next(item, v, beforeTo(schema), schema);
  output.v = _var;
  output.io = true;
  output.cp = code;
  output.f |= item.f & 1;
  return parse(B_markOutput(output, item));
};

// `append` takes a string or a blob as it is; every other entry is the string
// the value converts to, through the same encoders a JSON document uses.
const appendValue = (val: Val, fdVar: string, keyText: string, inList?: boolean): string => {
  const schema = val.s;
  const tagFlag = tagFlags[schema.type]!;
  // Neither `null` nor `undefined` is something a form can carry, so a field
  // declared as one is simply never written - which is what its own decode
  // reads back from an absent entry.
  if (tagFlag & (16 | 32)) {
    return "";
  }
  // Only a field is a checkbox. A repeated key is a list, and a list of
  // booleans is positional - dropping the false ones would lose the indices
  // the decoder reads back. (A checkbox *group* submits the values of the
  // checked boxes, which is `S.array(S.string)`.)
  if (!inList && isCheckbox(schema)) {
    // A literal settles the entry at compile time - `S.schema(true)` always
    // submits, `S.schema(false)` never does - so neither needs a guard.
    if (schema.const !== U) {
      return schema.const ? `${fdVar}.append(${keyText},"on");` : "";
    }
    // An unchecked box sends nothing, which is the whole of what the entry
    // list says about `false`, so that is what is written. A tri-state is the
    // one case the platform cannot express - absent and unchecked are the same
    // wire - so there `false` is spelled out to keep the third value apart, or
    // it would read back as the third one.
    // `S.optional(S.boolean, true)` therefore cannot round-trip: its `false`
    // omits, and an absent entry is its default. That default contradicts the
    // wire, where a missing checkbox means unchecked.
    return isAbsent(schema)
      ? `if(${val.i}!=null){${fdVar}.append(${keyText},${val.i}?"on":"false")}`
      : `if(${val.i}){${fdVar}.append(${keyText},"on")}`;
  }
  if (isList(schema)) {
    assertListItems(val, schema);
    const slots = schema.items!;
    if (slots.length) {
      // A tuple's slots each have their own schema, so there is no one item a
      // loop could convert - one append per slot, in order.
      let code = "";
      for (let idx = 0; idx < slots.length; idx++) {
        const slot = valGet(val, `${idx}`);
        code += B_mergeWithPathPrepend(slot, val, U, () =>
          appendValue(B_scope(slot), fdVar, keyText, true),
        );
      }
      return code;
    }
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
    // chain, and `B_mergeWithPathPrepend` below merges the item - the same val
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
  if (isAbsent(schema) && presentArm(schema).type !== unknownTag) {
    const presentSchema = presentArm(schema);
    if (presentSchema === schema) {
      // Nothing but the sentinels, so nothing is ever written.
      return "";
    }
    // Neither absent nor null is an entry, so the whole append sits behind one
    // loose guard - `!= null` is both sentinels and shorter than testing them
    // apart.
    // Compiled on a chain detached from the field val, the way json.ts's
    // guardedJsonPiece does, so the conversion's own code lands inside it.
    const inputVar = val.v();
    const detached = B_next(val, inputVar, presentSchema, presentSchema);
    detached.v = _var;
    detached.prev = U;
    return `if(${inputVar}!=null){${appendValue(detached, fdVar, keyText, inList)}}`;
  }
  if (tagFlag & 1 || presentArm(schema).type === unknownTag) {
    // An entry, or nothing: `append` stringifies whatever is neither, and
    // `"[object Object]"` is not what an `unknown` field held. `undefined`
    // and `null` are what its decode reads from no entry, so they write none
    // - which is the whole of what a wrapper around it adds, so it needs no
    // guard of its own.
    const v = val.v();
    return `if(${v}!=null){typeof ${v}==="string"||${v} instanceof ${B_embed(val, globalThis.Blob)}||${B_embedInvalidInput(val, formDataEntry)};${fdVar}.append(${keyText},${v});}`;
  }
  if ((tagFlag & 2) || ((tagFlag & 8192) && isBlobClass(schema.class))) {
    return `${fdVar}.append(${keyText},${val.i});`;
  }
  if (!(tagFlag & ((4 | 8) | 1024 | (2048 | 8192) | 256))) {
    return B_unsupportedDecode(val, schema, formData);
  }
  val.io = false;
  val.e = string;
  const converted = parse(val);
  return B_merge(converted) + `${fdVar}.append(${keyText},${converted.i});`;
};

const objectToFormData = (input: Val): Val => {
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
  // `S.strict` means "no entries but these", which a form submission cannot
  // honour: a browser appends entries of its own that no schema declared -
  // `_charset_` for a hidden input of that name, one per `dirname` attribute,
  // and an image button's `name.x`/`name.y`. Rejected where the pair is
  // written rather than silently read as `S.strip`. Asked of the declared
  // target only: writing a strict object says nothing about extra entries.
  if (target.additionalItems === "strict") {
    B_invalidOperation(
      input,
      `Can't decode FormData -> ${inputExpression(target)} with S.strict. A browser adds entries no schema declares, so use S.strip`,
    );
  }
  const objectVal = makeObjectVal(input, target);
  const entriesVar = B_varWithoutAllocation(input.g);
  B_hoistDecl(input, `${entriesVar}=${B_embed(input, readEntries)}(${input.v()})`);
  const properties = target.properties!;
  // Embedded once, however many list fields read through it.
  let listRead = "";
  for (const key in properties) {
    const schema = properties[key]!;
    const keyText = inlinedValueFromString(key);
    const present = presentArm(schema);
    const absent = isAbsent(schema);
    const list = isList(present);
    // A blank entry is read as absent where the field has an absent reading to
    // hand it to, unless the present arm names `""` as a value. A required
    // field is handed the entry as it stands and the target answers for
    // itself - `""` is an unchecked box to `S.boolean`, and a failure to
    // `S.nonEmpty` and `S.number`, each in its own words.
    const folds = absent && !list && !admitsBlank(present);
    const readVar = B_varWithoutAllocation(input.g);
    const slot = `${entriesVar}.get(${keyText})`;
    B_hoistDecl(
      input,
      list
        ? `${readVar}=${(listRead ||= B_embed(input, asList))}(${slot})`
        : // The `||void 0` is what leaves the var absent where the absent arm
          // itself writes nothing into it.
          `${readVar}=${slot}${folds && !absentWrites(schema) ? "||void 0" : ""}`,
    );

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
      s: list ? formDataList : folds ? formDataValue : formDataEntry,
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

    if (list) {
      assertListItems(item, present);
      if (absent && absentArm(schema).to !== U) {
        // No entries is the empty list, so nothing is ever absent to default.
        B_invalidOperation(
          item,
          `Can't decode form field -> ${inputExpression(present)} with a default. No entries is the empty list, so the default is never read`,
        );
      }
    } else if (present.type === unknownTag) {
      // One entry as it is: a repeated key is two where one belongs, and is
      // reported rather than read as the array its encode could never write.
      // Here and not in the field hook, which an `unknown` target never asks.
      item.cp = `Array.isArray(${readVar})&&${B_embedInvalidInput(item, formDataEntry)};`;
    }
    B_addObjectField(
      objectVal,
      key,
      // What "no entry" means is the reader's to say - the union rules have no
      // conversion into `undefined` or `null` to dispatch on. Everything else
      // is the field schema's own.
      absent ? readWrapped(item, schema, present, list ? U : folds) : parse(item),
    );
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
        : // Refused here, where the pair is still named: a union picks its
          // variant by narrowing the form to an object it isn't, and any other
          // target would run its own decoder on a `FormData` it never expects.
          (targetTagFlag & (1 | 8192))
            ? input
            : B_unsupportedDecode(input, input.s, target);
    };
  },
);
