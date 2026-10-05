import { expect, test as testCases } from "vitest";
import { repositoryDisplayPath, repositoryMetadata } from "./git-repository";

testCases.each([
  { repoRoot: "/srv/repo", expected: "/srv/repo" },
  { repoRoot: "/home/sam/code/app", expected: "app" },
  { repoRoot: "/home/sam/coder/app", expected: "/home/sam/coder/app" },
])("displays $repoRoot as $expected", ({ repoRoot, expected }) => {
  expect(repositoryDisplayPath({ home: "/home/sam", repoRoot })).toBe(expected);
});

testCases("recognizes linked worktrees from Git metadata", () => {
  expect(
    repositoryMetadata({
      output: "/repo/feature\n/repo/.git/worktrees/feature\n/repo/.git\n",
    }).isWorktree,
  ).toBe(true);
  expect(
    repositoryMetadata({ output: "/repo\n/repo/.git\n/repo/.git\n" })
      .isWorktree,
  ).toBe(false);
});
