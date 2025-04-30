
const esbuild = require("esbuild");

esbuild.build({
  entryPoints: ["app/javascript/packs/rich_editor.js"],
  bundle: true,
  outfile: "app/assets/builds/rich_editor.js",
  loader: { ".js": "jsx" },
  sourcemap: true,
  target: ["es6"]
}).catch(() => process.exit(1));