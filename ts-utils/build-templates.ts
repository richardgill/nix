#!/usr/bin/env bun
import { parseArgs } from "util";
import { join, dirname, basename, relative } from "path";
import {
  mkdirSync,
  readFileSync,
  writeFileSync,
  cpSync,
  readdirSync,
  existsSync,
  statSync,
} from "fs";
import Handlebars from "handlebars";
import { z } from "zod";
import { directories, rootTemplates, DOT_FILES_PATH } from "./template-config";

const templateDataSchema = z.object({
  isDarwin: z.boolean(),
  isLinux: z.boolean(),
  homeDir: z.string(),
  homeDirectory: z.string(),
  zshPath: z.string(),
  coreUtilsPath: z.string(),
  musicDir: z.string(),
  anthropicApiKeyPath: z.string(),
  kagiApiKeyPath: z.string(),
  tavilyApiKeyPath: z.string(),
  openaiApiKeyPath: z.string(),
  joistApiKeyPath: z.string(),
  defaultShell: z.string(),
  catppuccinPlugin: z.string(),
  resurrectPlugin: z.string(),
  continuumPlugin: z.string(),
  firefoxProfilePath: z.string(),
  firefoxProfilePathUrlEncoded: z.string(),
  defaultEngineIdHash: z.string(),
  profilePath: z.string(),
});

type TemplateData = z.infer<typeof templateDataSchema>;

const parseCliArgs = () => {
  const { values } = parseArgs({
    options: {
      "data-file": { type: "string", short: "d" },
      outDir: { type: "string", short: "o" },
    },
  });

  if (!values["data-file"]) {
    throw new Error("--data-file (-d) is required: path to JSON data file");
  }
  if (!values.outDir) {
    throw new Error("--outDir (-o) is required: output directory path");
  }

  return {
    dataFile: values["data-file"],
    outDir: values.outDir,
  };
};

const loadData = (dataPath: string): TemplateData => {
  const content = readFileSync(dataPath, "utf-8");
  return templateDataSchema.parse(JSON.parse(content));
};

const ensureDir = (path: string) => {
  mkdirSync(dirname(path), { recursive: true });
};

const renderTemplate = (
  templatePath: string,
  outputPath: string,
  data: TemplateData,
) => {
  const templateContent = readFileSync(templatePath, "utf-8");
  const template = Handlebars.compile(templateContent);
  const rendered = template(data);

  ensureDir(outputPath);
  writeFileSync(outputPath, rendered);
  console.log(`Rendered: ${relative(process.cwd(), outputPath)}`);
};

const copyFile = (sourcePath: string, outputPath: string) => {
  ensureDir(outputPath);
  cpSync(sourcePath, outputPath);
  console.log(`Copied: ${relative(process.cwd(), outputPath)}`);
};

const registerPartialsFromDir = (partialsPath: string) => {
  if (!existsSync(partialsPath)) return;

  const files = readdirSync(partialsPath).filter((f) => f.endsWith(".md"));
  for (const file of files) {
    const name = basename(file, ".md");
    const content = readFileSync(join(partialsPath, file), "utf-8");
    Handlebars.registerPartial(name, content);
    console.log(`Registered partial: ${name}`);
  }
};

const processDirectory = (
  rootDir: string,
  outDir: string,
  dirName: string,
  data: TemplateData,
) => {
  const sourceDir = join(rootDir, DOT_FILES_PATH, dirName);
  const outputDir = join(outDir, dirName);

  const processRecursively = (currentPath: string, currentOutPath: string) => {
    const entries = readdirSync(currentPath, { withFileTypes: true });

    for (const entry of entries) {
      const sourcePath = join(currentPath, entry.name);
      const relPath = relative(sourceDir, sourcePath);

      if (entry.isDirectory()) {
        // Skip partials directory (already processed for Handlebars registration)
        if (entry.name === "partials") continue;

        // Recurse into subdirectory
        processRecursively(sourcePath, join(currentOutPath, entry.name));
      } else if (entry.isFile()) {
        if (entry.name.endsWith(".hbs")) {
          // Render template (remove .hbs extension)
          const outputName = entry.name.replace(/\.hbs$/, "");
          const outputPath = join(currentOutPath, outputName);
          renderTemplate(sourcePath, outputPath, data);
        } else {
          // Copy static file
          const outputPath = join(currentOutPath, entry.name);
          copyFile(sourcePath, outputPath);
        }
      }
    }
  };

  console.log(`\nProcessing: ${dirName}`);
  processRecursively(sourceDir, outputDir);
};

const build = () => {
  const { dataFile, outDir } = parseCliArgs();

  // Root is one level up from ts-utils/
  const rootDir = dirname(import.meta.dir);

  const data = loadData(dataFile);
  console.log("Building templates with data:", JSON.stringify(data, null, 2));

  // Create output directory
  mkdirSync(outDir, { recursive: true });

  // Register partials from all directories that have a partials folder
  for (const dir of directories) {
    const partialsPath = join(rootDir, DOT_FILES_PATH, dir, "partials");
    registerPartialsFromDir(partialsPath);
  }

  // Process each directory
  for (const dir of directories) {
    processDirectory(rootDir, outDir, dir, data);
  }

  // Process root-level templates
  console.log("\nProcessing root templates");
  for (const template of rootTemplates) {
    const sourcePath = join(rootDir, DOT_FILES_PATH, template);
    const outputName = template.replace(/\.hbs$/, "");
    // Put root templates in their own directory (e.g., zprofile/zprofile)
    const outputPath = join(outDir, outputName, outputName);
    renderTemplate(sourcePath, outputPath, data);
  }

  console.log("\nBuild complete!");
};

build();
