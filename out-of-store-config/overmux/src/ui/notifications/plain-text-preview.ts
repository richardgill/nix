import { toString } from "mdast-util-to-string";
import remarkGfm from "remark-gfm";
import remarkParse from "remark-parse";
import stripMarkdown from "strip-markdown";
import { unified } from "unified";

const previewProcessor = unified()
  .use(remarkParse)
  .use(remarkGfm)
  .use(stripMarkdown);

export const toPlainTextPreview = (body: string) => {
  const tree = previewProcessor.runSync(previewProcessor.parse(body));
  return tree.children.map((node) => toString(node)).join(" ").replace(/\s+/g, " ").trim();
};
