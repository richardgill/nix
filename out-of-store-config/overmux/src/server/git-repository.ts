import { execFile } from "node:child_process";
import { homedir } from "node:os";
import { join, sep } from "node:path";
import { promisify } from "node:util";
import { defineResourceContract } from "overmux";
import { z } from "zod";

const execFileAsync = promisify(execFile);
const inputSchema = z.object({ cwd: z.string().startsWith("/") }).strict();
const outputSchema = z
  .object({
    displayPath: z.string(),
    isWorktree: z.boolean(),
    repoRoot: z.string().startsWith("/"),
  })
  .strict();

export const repositoryDisplayPath = ({
  home,
  repoRoot,
}: {
  home: string;
  repoRoot: string;
}) => {
  const codeRoot = `${join(home, "code")}${sep}`;
  return repoRoot.startsWith(codeRoot)
    ? repoRoot.slice(codeRoot.length)
    : repoRoot;
};

export const repositoryMetadata = ({ output }: { output: string }) => {
  const [repoRoot, gitDir, commonGitDir] = output.trim().split("\n");
  if (!repoRoot || !gitDir || !commonGitDir)
    throw new Error("Git did not return repository metadata");
  return {
    displayPath: repositoryDisplayPath({ home: homedir(), repoRoot }),
    isWorktree: gitDir !== commonGitDir,
    repoRoot,
  };
};

export const gitRepositoryResource = {
  contract: defineResourceContract({
    input: inputSchema,
    output: outputSchema,
  }),
  kind: "query" as const,
  read: async (
    { cwd }: z.infer<typeof inputSchema>,
    { signal }: { signal: AbortSignal },
  ) => {
    const { stdout } = await execFileAsync(
      "git",
      [
        "-C",
        cwd,
        "rev-parse",
        "--show-toplevel",
        "--path-format=absolute",
        "--git-dir",
        "--git-common-dir",
      ],
      { encoding: "utf8", signal },
    );
    return repositoryMetadata({ output: stdout });
  },
};
