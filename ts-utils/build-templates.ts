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
import { directories, rootTemplates, DOT_FILES_PATH, agents, AgentName } from "./template-config";

Handlebars.registerHelper("eq", (a, b) => a === b);

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
  beeperApiTokenPath: z.string(),
  defaultShell: z.string(),
  catppuccinPlugin: z.string(),
  resurrectPlugin: z.string(),
  continuumPlugin: z.string(),
  firefoxProfilePath: z.string(),
  firefoxProfilePathUrlEncoded: z.string(),
  defaultEngineIdHash: z.string(),
  profilePath: z.string(),
}).strict();

type TemplateData = z.infer<typeof templateDataSchema>;
type RenderContext = TemplateData & { agent?: string };

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
  data: RenderContext,
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

const processFileOrDir = (
  sourcePath: string,
  outputPath: string,
  data: RenderContext,
) => {
  const stat = statSync(sourcePath);
  if (stat.isDirectory()) {
    const entries = readdirSync(sourcePath, { withFileTypes: true });
    for (const entry of entries) {
      processFileOrDir(
        join(sourcePath, entry.name),
        join(outputPath, entry.name),
        data,
      );
    }
  } else if (stat.isFile()) {
    if (sourcePath.endsWith(".hbs")) {
      const outputWithoutHbs = outputPath.replace(/\.hbs$/, "");
      renderTemplate(sourcePath, outputWithoutHbs, data);
    } else {
      copyFile(sourcePath, outputPath);
    }
  }
};

const processSharedContent = (
  rootDir: string,
  outDir: string,
  data: TemplateData,
) => {
  const sharedPath = join(rootDir, DOT_FILES_PATH, "ai-agents/shared");
  const commandsPath = join(rootDir, DOT_FILES_PATH, "ai-agents/commands");

  for (const [agent, config] of Object.entries(agents) as [AgentName, typeof agents[AgentName]][]) {
    const agentData: RenderContext = { ...data, agent };

    // Process shared/skills/
    if (config.sharedSkills && existsSync(sharedPath)) {
      const sharedSkillsPath = join(sharedPath, "skills");
      if (existsSync(sharedSkillsPath)) {
        const targetSkillsPath = join(outDir, "ai-agents", agent, "skills");
        console.log(`\nProcessing shared/skills/ for ${agent}`);

        const entries = readdirSync(sharedSkillsPath, { withFileTypes: true });
        for (const entry of entries) {
          if (entry.isDirectory()) {
            const sourcePath = join(sharedSkillsPath, entry.name);
            const destPath = join(targetSkillsPath, entry.name);
            processFileOrDir(sourcePath, destPath, agentData);
          }
        }
      }
    }

    // Process shared/agents/
    if (config.sharedAgents && existsSync(sharedPath)) {
      const sharedAgentsPath = join(sharedPath, "agents");
      if (existsSync(sharedAgentsPath)) {
        const targetAgentsPath = join(outDir, "ai-agents", agent, "agents");
        console.log(`\nProcessing shared/agents/ for ${agent}`);

        const entries = readdirSync(sharedAgentsPath, { withFileTypes: true });
        for (const entry of entries) {
          if (entry.isFile()) {
            const sourcePath = join(sharedAgentsPath, entry.name);
            const outputName = entry.name.replace(/\.hbs$/, "");
            const destPath = join(targetAgentsPath, outputName);
            if (entry.name.endsWith(".hbs")) {
              renderTemplate(sourcePath, destPath, agentData);
            } else {
              copyFile(sourcePath, destPath);
            }
          }
        }
      }
    }

    // Process commands/
    if (config.commands && existsSync(commandsPath)) {
      const targetCommandsPath = join(outDir, "ai-agents", agent, config.commandsFolder);
      console.log(`\nProcessing commands/ for ${agent}`);
      processFileOrDir(commandsPath, targetCommandsPath, agentData);
    }
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
  const isAiAgents = dirName === "ai-agents";

  const processRecursively = (
    currentPath: string,
    currentOutPath: string,
    context: RenderContext,
  ) => {
    const entries = readdirSync(currentPath, { withFileTypes: true });

    for (const entry of entries) {
      const sourcePath = join(currentPath, entry.name);
      const relPath = relative(sourceDir, sourcePath);

      if (entry.isDirectory()) {
        // Skip partials, shared, and commands directories (processed separately)
        if (entry.name === "partials" || entry.name === "shared" || entry.name === "commands") continue;

        // Detect agent context for ai-agents subdirectories
        let subContext = context;
        if (isAiAgents && entry.name in agents) {
          subContext = { ...context, agent: entry.name };
        }

        // Recurse into subdirectory
        processRecursively(sourcePath, join(currentOutPath, entry.name), subContext);
      } else if (entry.isFile()) {
        if (entry.name.endsWith(".hbs")) {
          // Render template (remove .hbs extension)
          const outputName = entry.name.replace(/\.hbs$/, "");
          const outputPath = join(currentOutPath, outputName);
          renderTemplate(sourcePath, outputPath, context);
        } else {
          // Copy static file
          const outputPath = join(currentOutPath, entry.name);
          copyFile(sourcePath, outputPath);
        }
      }
    }
  };

  console.log(`\nProcessing: ${dirName}`);
  processRecursively(sourceDir, outputDir, data);
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

  // Process shared content (skills, agents) for each target agent
  processSharedContent(rootDir, outDir, data);

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
