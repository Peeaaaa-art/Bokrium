const esbuild = require("esbuild");

(async () => {
  const ctx = await esbuild.context({
    entryPoints: ["app/javascript/application.js"],
    bundle: true,
    outdir: "app/assets/builds",
    loader: { ".js": "jsx" },
    sourcemap: true,
    target: ["es6"]
  });

  // 引数に `--watch` があれば watch を有効に
  if (process.argv.includes("--watch")) {
    await ctx.watch();
    console.log("👀 Watching for changes...");
  } else {
    await ctx.rebuild();
    await ctx.dispose();
    console.log("✅ Build finished (once)");
  }
})();