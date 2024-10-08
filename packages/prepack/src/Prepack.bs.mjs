// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Fs from "fs";
import * as Execa from "execa";
import * as Rollup from "rollup";
import * as Nodefs from "node:fs";
import * as Nodepath from "node:path";
import * as Core__JSON from "@rescript/core/src/Core__JSON.bs.mjs";
import * as Core__List from "@rescript/core/src/Core__List.bs.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.bs.mjs";
import PluginReplace from "@rollup/plugin-replace";

var projectPath = ".";

var artifactsPath = Nodepath.join(projectPath, "packages/artifacts");

var sourePaths = [
  "package.json",
  "node_modules",
  "src",
  "rescript.json",
  "README.md",
  "RescriptSchema.gen.d.ts",
];

var jsInputPath = Nodepath.join(artifactsPath, "src/S.js");

function update(json, path, value) {
  var dict = Core__JSON.Decode.object(json);
  var dict$1 = dict !== undefined ? Object.assign({}, dict) : {};
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
    force: true,
  });
}

Nodefs.mkdirSync(artifactsPath);

sourePaths.forEach(function (path) {
  Fs.cpSync(
    Nodepath.join(projectPath, path),
    Nodepath.join(artifactsPath, path),
    {
      recursive: true,
    }
  );
});

function updateJsonFile(src, path, value) {
  var packageJsonData = Nodefs.readFileSync(src, {
    encoding: "utf8",
  });
  var packageJson = JSON.parse(packageJsonData.toString());
  var updatedPackageJson = JSON.stringify(
    update(packageJson, Core__List.fromArray(path), value),
    undefined,
    2
  );
  Nodefs.writeFileSync(src, Buffer.from(updatedPackageJson), {
    encoding: "utf8",
  });
}

Execa.execaSync("npm", ["run", "res:build"], {
  cwd: artifactsPath,
});

var bundle = await Rollup.rollup({
  input: jsInputPath,
  external: [/S_Core\.bs\.mjs/],
});

var output = [
  {
    file: Nodepath.join(artifactsPath, "dist/S.js"),
    format: "cjs",
    exports: "named",
    plugins: [
      PluginReplace({
        values: Object.fromEntries([
          ["S_Core.bs.mjs", "../src/S_Core.bs.js"],
          ["rescript/lib/es6", "rescript/lib/js"],
        ]),
      }),
    ],
  },
  {
    file: Nodepath.join(artifactsPath, "dist/S.mjs"),
    format: "es",
    exports: "named",
    plugins: [
      PluginReplace({
        values: Object.fromEntries([["S_Core.bs.mjs", "../src/S_Core.bs.mjs"]]),
      }),
    ],
  },
];

for (var idx = 0, idx_finish = output.length; idx < idx_finish; ++idx) {
  var outpuOptions = output[idx];
  await bundle.write(outpuOptions);
}

await bundle.close();

Fs.rmSync(Nodepath.join(artifactsPath, "lib"), {
  recursive: true,
  force: true,
});

updateJsonFile(
  Nodepath.join(artifactsPath, "rescript.json"),
  ["package-specs", "module"],
  "commonjs"
);

updateJsonFile(
  Nodepath.join(artifactsPath, "rescript.json"),
  ["suffix"],
  ".bs.js"
);

Execa.execaSync("npm", ["run", "res:build"], {
  cwd: artifactsPath,
});

updateJsonFile(
  Nodepath.join(artifactsPath, "package.json"),
  ["type"],
  "commonjs"
);

Fs.rmSync(Nodepath.join(artifactsPath, "lib"), {
  recursive: true,
  force: true,
});

Fs.rmSync(Nodepath.join(artifactsPath, "node_modules"), {
  recursive: true,
  force: true,
});

export {};
/* artifactsPath Not a pure module */
