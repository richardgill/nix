#!/usr/bin/env bun
import { mkdirSync, rmSync, writeFileSync } from "fs";
import { basename, dirname, join } from "path";
import { parseArgs } from "util";

const parseCliArgs = () => {
  const { values } = parseArgs({
    options: {
      outfile: { type: "string", short: "o" },
    },
  });

  if (!values.outfile) {
    throw new Error("--outfile (-o) is required");
  }

  return { outfile: values.outfile };
};

const bundleTemplates = async (outfile: string) => {
  const entrypoint = join(import.meta.dir, ".build-templates-entrypoint.ts");
  const source = 'import { buildTemplates } from "./build-templates";\nbuildTemplates();\n';
  writeFileSync(entrypoint, source);
  mkdirSync(dirname(outfile), { recursive: true });

  try {
    const result = await Bun.build({
      entrypoints: [entrypoint],
      outdir: dirname(outfile),
      naming: basename(outfile),
      target: "bun",
    });
    if (!result.success) {
      throw new Error(result.logs.map(String).join("\n"));
    }
  } finally {
    rmSync(entrypoint, { force: true });
  }
};

const main = async () => {
  const { outfile } = parseCliArgs();
  await bundleTemplates(outfile);
};

await main();
