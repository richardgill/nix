import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { defineOperation } from "overmux";
import { z } from "zod";

const execFileAsync = promisify(execFile);
const inputSchema = z.object({ cwd: z.string().startsWith("/") }).strict();
const outputSchema = z.object({ url: z.string().url() }).strict();

type ExecuteFile = (options: {
  args: string[];
  cwd: string;
  signal?: AbortSignal;
}) => Promise<{ stdout: string }>;

const executeGh: ExecuteFile = async ({ args, cwd, signal }) =>
  execFileAsync("gh", args, { cwd, encoding: "utf8", signal });

const commandOutput = (cause: unknown) => {
  if (!(cause instanceof Error)) return String(cause);
  const stderr = (cause as Error & { stderr?: unknown }).stderr;
  return `${cause.message}\n${typeof stderr === "string" ? stderr : ""}`;
};

export const pullRequestLookupMessage = (cause: unknown) => {
  const output = commandOutput(cause);
  if (/not a git repository|unable to determine.*repository/i.test(output)) {
    return "This folder is not a Git repository.";
  }
  if (/no pull requests? found|no pull requests? for branch/i.test(output)) {
    return "No pull request was found for the current branch.";
  }
  if (/auth login|not logged into any github hosts|authentication/i.test(output)) {
    return "GitHub CLI is not authenticated. Run gh auth login.";
  }
  if (/ENOENT/.test(output)) return "GitHub CLI (gh) is not installed.";
  return "Could not find a pull request for this folder.";
};

export const findPullRequest = async ({
  cwd,
  executeFile = executeGh,
  signal,
}: {
  cwd: string;
  executeFile?: ExecuteFile;
  signal?: AbortSignal;
}) => {
  try {
    const { stdout } = await executeFile({
      args: ["pr", "view", "--json", "url"],
      cwd,
      signal,
    });
    return outputSchema.parse(JSON.parse(stdout));
  } catch (cause) {
    throw new Error(pullRequestLookupMessage(cause));
  }
};

export const findPullRequestOperation = defineOperation({
  input: inputSchema,
  output: outputSchema,
  handle: ({ cwd }, { signal }) => findPullRequest({ cwd, signal }),
});
