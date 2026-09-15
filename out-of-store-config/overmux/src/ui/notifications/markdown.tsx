import Markdown from "react-markdown";
import remarkGfm from "remark-gfm";

export const NotificationMarkdown = ({ body }: { body: string }) => (
  <div className="markdown break-words leading-7 text-foreground/85">
    <Markdown remarkPlugins={[remarkGfm]} skipHtml>
      {body}
    </Markdown>
  </div>
);
