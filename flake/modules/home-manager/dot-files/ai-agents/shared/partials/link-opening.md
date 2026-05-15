## Opening links vs browser automation

When the user asks to open/show/launch a URL or link on their machine, use:

```bash
open '<url>'
```

Do not use the browser skill for plain link opening.

Use the browser skill only when the assistant needs to inspect, automate, or interact with the page: click, fill, login, scrape, extract data, test UI, take screenshots, or report what is visible.

If ambiguous, ask: “Should I just open it for you, or should I inspect/interact with it?”
