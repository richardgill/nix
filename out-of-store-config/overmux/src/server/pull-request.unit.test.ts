import { expect, test as testCases, vi } from "vitest";

import { findPullRequest } from "./pull-request";

testCases("resolves the current branch pull request with gh", async () => {
  const executeFile = vi.fn(async () => ({
    stdout: '{"url":"https://github.com/acme/project/pull/42"}',
  }));

  await expect(
    findPullRequest({ cwd: "/home/rich/code/project", executeFile }),
  ).resolves.toEqual({ url: "https://github.com/acme/project/pull/42" });
  expect(executeFile).toHaveBeenCalledWith({
    args: ["pr", "view", "--json", "url"],
    cwd: "/home/rich/code/project",
    signal: undefined,
  });
});

testCases.each([
  {
    error: "no pull requests found for branch \"main\"",
    message: "No pull request was found for the current branch.",
  },
  {
    error: "fatal: not a git repository (or any of the parent directories): .git",
    message: "This folder is not a Git repository.",
  },
  {
    error: "To get started with GitHub CLI, please run: gh auth login",
    message: "GitHub CLI is not authenticated. Run gh auth login.",
  },
])("reports a friendly error for $error", async ({ error, message }) => {
  const executeFile = async () => Promise.reject(new Error(error));

  await expect(
    findPullRequest({ cwd: "/home/rich/code/project", executeFile }),
  ).rejects.toThrow(message);
});
