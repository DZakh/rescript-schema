// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Fs from "fs";
import * as Execa from "execa";
import * as Rollup from "rollup";
import * as Nodefs from "node:fs";
import * as Nodepath from "node:path";
import * as Core__JSON from "@rescript/core/src/Core__JSON.res.mjs";
import * as Core__List from "@rescript/core/src/Core__List.res.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.res.mjs";
import * as PluginNodeResolve from "@rollup/plugin-node-resolve";

var projectPath = ".";

var artifactsPath = Nodepath.join(projectPath, "packages/artifacts");

var sourePaths = [
  "package.json",
  "node_modules",
  "src",
  "rescript.json",
  "README.md",
  "RescriptSchema.gen.d.ts"
];

function update(json, path, value) {
  var dict = Core__JSON.Decode.object(json);
  var dict$1 = dict !== undefined ? Object.assign({}, dict) : ({});
  if (!path) {
    return value;
  }
  var path$1 = path.tl;
  var key = path.hd;
  if (path$1) {
    dict$1[key] = update(Core__Option.getOr(dict$1[key], {}), path$1, value);
    return dict$1;
  } else {
    dict$1[key] = value;
    return dict$1;
  }
}

if (Nodefs.existsSync(artifactsPath)) {
  Fs.rmSync(artifactsPath, {
        recursive: true,
        force: true
      });
}

Nodefs.mkdirSync(artifactsPath);

var filesMapping = [
  [
    "Error",
    "S.$$Error.$$class"
  ],
  [
    "string",
    "S.string"
  ],
  [
    "boolean",
    "S.bool"
  ],
  [
    "int32",
    "S.$$int"
  ],
  [
    "number",
    "S.$$float"
  ],
  [
    "bigint",
    "S.bigint"
  ],
  [
    "json",
    "S.json"
  ],
  [
    "never",
    "S.never"
  ],
  [
    "unknown",
    "S.unknown"
  ],
  [
    "undefined",
    "S.unit"
  ],
  [
    "optional",
    "S.js_optional"
  ],
  [
    "nullable",
    "S.$$null"
  ],
  [
    "nullish",
    "S.nullable"
  ],
  [
    "array",
    "S.array"
  ],
  [
    "unnest",
    "S.unnest"
  ],
  [
    "record",
    "S.dict"
  ],
  [
    "jsonString",
    "S.jsonString"
  ],
  [
    "union",
    "S.js_union"
  ],
  [
    "object",
    "S.object"
  ],
  [
    "schema",
    "S.js_schema"
  ],
  [
    "safe",
    "S.js_safe"
  ],
  [
    "safeAsync",
    "S.js_safeAsync"
  ],
  [
    "reverse",
    "S.reverse"
  ],
  [
    "convertOrThrow",
    "S.convertOrThrow"
  ],
  [
    "convertToJsonOrThrow",
    "S.convertToJsonOrThrow"
  ],
  [
    "convertToJsonStringOrThrow",
    "S.convertToJsonStringOrThrow"
  ],
  [
    "reverseConvertOrThrow",
    "S.reverseConvertOrThrow"
  ],
  [
    "reverseConvertToJsonOrThrow",
    "S.reverseConvertToJsonOrThrow"
  ],
  [
    "reverseConvertToJsonStringOrThrow",
    "  S.reverseConvertToJsonStringOrThrow"
  ],
  [
    "parseOrThrow",
    "S.parseOrThrow"
  ],
  [
    "parseJsonOrThrow",
    "S.parseJsonOrThrow"
  ],
  [
    "parseJsonStringOrThrow",
    "S.parseJsonStringOrThrow"
  ],
  [
    "parseAsyncOrThrow",
    "S.parseAsyncOrThrow"
  ],
  [
    "assertOrThrow",
    "S.assertOrThrow"
  ],
  [
    "recursive",
    "S.recursive"
  ],
  [
    "merge",
    "S.js_merge"
  ],
  [
    "strict",
    "S.strict"
  ],
  [
    "deepStrict",
    "S.deepStrict"
  ],
  [
    "strip",
    "S.strip"
  ],
  [
    "deepStrip",
    "S.deepStrip"
  ],
  [
    "custom",
    "S.js_custom"
  ],
  [
    "standard",
    "S.standard"
  ],
  [
    "tuple",
    "S.tuple"
  ],
  [
    "asyncParserRefine",
    "S.js_asyncParserRefine"
  ],
  [
    "refine",
    "S.js_refine"
  ],
  [
    "transform",
    "S.js_transform"
  ],
  [
    "description",
    "S.description"
  ],
  [
    "describe",
    "S.describe"
  ],
  [
    "name",
    "S.js_name"
  ],
  [
    "setName",
    "S.setName"
  ],
  [
    "removeTypeValidation",
    "S.removeTypeValidation"
  ],
  [
    "compile",
    "S.compile"
  ],
  [
    "port",
    "S.port"
  ],
  [
    "numberMin",
    "S.floatMin"
  ],
  [
    "numberMax",
    "S.floatMax"
  ],
  [
    "arrayMinLength",
    "S.arrayMinLength"
  ],
  [
    "arrayMaxLength",
    "S.arrayMaxLength"
  ],
  [
    "arrayLength",
    "S.arrayLength"
  ],
  [
    "stringMinLength",
    "S.stringMinLength"
  ],
  [
    "stringMaxLength",
    "S.stringMaxLength"
  ],
  [
    "stringLength",
    "S.stringLength"
  ],
  [
    "email",
    "S.email"
  ],
  [
    "uuid",
    "S.uuid"
  ],
  [
    "cuid",
    "S.cuid"
  ],
  [
    "url",
    "S.url"
  ],
  [
    "pattern",
    "S.pattern"
  ],
  [
    "datetime",
    "S.datetime"
  ],
  [
    "trim",
    "S.trim"
  ],
  [
    "setGlobalConfig",
    "S.setGlobalConfig"
  ]
];

Nodefs.writeFileSync("./src/S.mjs", Buffer.from(["import * as S from \"./S_Core.res.mjs\";"].concat(filesMapping.map(function (param) {
                    return "export const " + param[0] + " = " + param[1];
                  })).join("\n")), {
      encoding: "utf8"
    });

Nodefs.writeFileSync("./src/S.js", Buffer.from(["var S = require(\"./S_Core.res.js\");"].concat(filesMapping.map(function (param) {
                    return "exports." + param[0] + " = " + param[1];
                  })).join("\n")), {
      encoding: "utf8"
    });

sourePaths.forEach(function (path) {
      Fs.cpSync(Nodepath.join(projectPath, path), Nodepath.join(artifactsPath, path), {
            recursive: true
          });
    });

function updateJsonFile(src, path, value) {
  var packageJsonData = Nodefs.readFileSync(src, {
        encoding: "utf8"
      });
  var packageJson = JSON.parse(packageJsonData.toString());
  var updatedPackageJson = JSON.stringify(update(packageJson, Core__List.fromArray(path), value), undefined, 2);
  Nodefs.writeFileSync(src, Buffer.from(updatedPackageJson), {
        encoding: "utf8"
      });
}

Execa.execaSync("npm", [
      "run",
      "res:build"
    ], {
      cwd: artifactsPath
    });

async function resolveRescriptRuntime(format, input, output) {
  var bundle = await Rollup.rollup({
        input: Nodepath.join(artifactsPath, input),
        plugins: [PluginNodeResolve.nodeResolve()]
      });
  await bundle.write({
        file: Nodepath.join(artifactsPath, output),
        format: format,
        exports: "named"
      });
  return await bundle.close();
}

await resolveRescriptRuntime("es", "src/S_Core.res.mjs", "src/S_Core.res.mjs");

await resolveRescriptRuntime("cjs", "src/S_Core.res.mjs", "src/S_Core.res.js");

await resolveRescriptRuntime("cjs", "src/S.res.mjs", "src/S.res.js");

updateJsonFile(Nodepath.join(artifactsPath, "package.json"), ["type"], "commonjs");

updateJsonFile(Nodepath.join(artifactsPath, "package.json"), ["private"], false);

Fs.rmSync(Nodepath.join(artifactsPath, "lib"), {
      recursive: true,
      force: true
    });

Fs.rmSync(Nodepath.join(artifactsPath, "node_modules"), {
      recursive: true,
      force: true
    });

export {
  
}
/* artifactsPath Not a pure module */
