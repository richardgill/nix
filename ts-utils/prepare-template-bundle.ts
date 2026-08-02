#!/usr/bin/env bun
import { mkdirSync, rmSync, writeFileSync } from "fs";
import { basename, dirname, join } from "path";
import { parseArgs } from "util";
import { remoteSkills, type RemoteSkill } from "./agent-config";

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

const resolveRemoteSkillUrl = (url: string) => {
  const resolved = new URL(url);
  if (resolved.hostname === "github.com" && resolved.pathname.includes("/blob/")) {
    resolved.searchParams.set("raw", "1");
  }
  return resolved.toString();
};

const readSkillName = (content: string) => {
  const frontmatter = content.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)?.[1];
  const name = frontmatter?.match(/^name:\s*["']?([^"'\s]+)["']?\s*$/m)?.[1];
  if (!name) {
    throw new Error("downloaded content does not contain a skill name");
  }
  return name;
};

const downloadRemoteSkill = async (name: string, skill: RemoteSkill) => {
  const url = resolveRemoteSkillUrl(skill.url);
  const response = await fetch(url, { signal: AbortSignal.timeout(30_000) });
  if (!response.ok) {
    throw new Error(`${name}: ${response.status} ${response.statusText} from ${url}`);
  }

  const content = await response.text();
  const downloadedName = readSkillName(content);
  if (downloadedName !== name) {
    throw new Error(`${name}: downloaded skill is named ${downloadedName}`);
  }

  console.log(`Downloaded remote skill: ${name}`);
  return [name, content] as const;
};

const downloadRemoteSkills = async () =>
  Object.fromEntries(
    await Promise.all(
      Object.entries(remoteSkills).map(([name, skill]) =>
        downloadRemoteSkill(name, skill),
      ),
    ),
  );

const bundleTemplates = async (outfile: string, skills: Record<string, string>) => {
  const entrypoint = join(import.meta.dir, ".build-templates-entrypoint.ts");
  const source = `import { buildTemplates } from "./build-templates";\nbuildTemplates(${JSON.stringify(skills)});\n`;
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
  const skills = await downloadRemoteSkills();
  await bundleTemplates(outfile, skills);
};

await main();
