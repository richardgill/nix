import { expect, test as testCases } from "vitest";

import { toPlainTextPreview } from "./plain-text-preview";

testCases.each([
  { body: "# Finished\n\nSome **bold and _nested_** text.", expected: "Finished Some bold and nested text." },
  { body: "[Review PR](https://example.com) and `inline code`", expected: "Review PR and inline code" },
  { body: "- [x] Done\n- [ ] Pending\n\n~~Old~~ new", expected: "Done Pending Old new" },
  { body: "![Build status](https://example.com/image.png)", expected: "Build status" },
  { body: "Text before\n\n```ts\nconst value = 1;\n```\n\nText after", expected: "Text before Text after" },
  { body: "| Column |\n| --- |\n| Value |\n\nSummary", expected: "Summary" },
  { body: "<script>alert(1)</script>\n\nSafe", expected: "Safe" },
  { body: "Literal \\* text &amp; punctuation!\n\nNext paragraph.", expected: "Literal * text & punctuation! Next paragraph." },
  { body: "  \n\t", expected: "" },
])("plain-text preview: $expected", ({ body, expected }) => {
  expect(toPlainTextPreview(body)).toBe(expected);
});
