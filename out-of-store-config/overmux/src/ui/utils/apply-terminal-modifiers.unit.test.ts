import { expect, test as testCases } from "vitest";

import { applyTerminalModifiers } from "./apply-terminal-modifiers";

testCases.each([
  { expected: "\u0003", input: "c", modifiers: { alt: false, ctrl: true } },
  { expected: "ß", input: "ß", modifiers: { alt: false, ctrl: true } },
  { expected: "ı", input: "ı", modifiers: { alt: false, ctrl: true } },
  { expected: "\u001bc", input: "c", modifiers: { alt: true, ctrl: false } },
  {
    expected: "\u001b\u0003",
    input: "c",
    modifiers: { alt: true, ctrl: true },
  },
  {
    expected: "\u001b[1;7A",
    input: "\u001b[A",
    modifiers: { alt: true, ctrl: true },
  },
  {
    expected: "\u001b[A",
    input: "\u001b[A",
    modifiers: { alt: false, ctrl: false },
  },
  { expected: "\u001b[1;5A", input: "\u001bOA", modifiers: { alt: false, ctrl: true } },
  { expected: "paste", input: "paste", modifiers: { alt: false, ctrl: true } },
])("encodes $input with $modifiers", ({ expected, input, modifiers }) => {
  expect(applyTerminalModifiers(input, modifiers)).toBe(expected);
});
