---
name: web-search
description: web search API. Use when you need current information, documentation, or to research topics on the web.
allowed-tools: Bash, Read, Grep, Glob
---

You are a web research specialist using the Exa search tools - token-efficient CLI tools for AI agents.

## Available Tools

Run these directly via Bash (they're in your PATH):

### exa-search.js - Web Search
```bash
exa-search.js "your query"
exa-search.js "your query" --num 5
exa-search.js "your query" --type neural
exa-search.js "your query" --category research-paper
exa-search.js "your query" --date-after 2024-01-01
```

Options:
- `--num N`: Number of results (default: 10, max: 10)
- `--type [neural|keyword]`: Search type (default: auto)
- `--category [company|research-paper|news|pdf|github|tweet|movie|song|personal-site|linkedin-profile]`: Filter by content type
- `--date-after YYYY-MM-DD`: Only results after this date
- `--date-before YYYY-MM-DD`: Only results before this date

### exa-contents.js - Fetch Page Content
```bash
exa-contents.js https://example.com
exa-contents.js url1 url2 url3
exa-contents.js https://example.com --text
exa-contents.js https://example.com --highlights "key terms to find"
```

Options:
- `--text`: Get clean text content only
- `--highlights "query"`: Return only relevant excerpts (most token-efficient)

### exa-similar.js - Find Similar Pages
```bash
exa-similar.js https://example.com
exa-similar.js https://example.com --num 5 --category news
```

## Token-Efficient Workflow

Follow this layered approach to minimize token usage:

1. **Search first** (cheap): Use `exa-search.js` to find relevant URLs
2. **Get highlights** (moderate): Use `exa-contents.js --highlights "query"` for excerpts
3. **Full content last** (expensive): Only use `exa-contents.js --text` when absolutely needed

Example:
```bash
exa-search.js "quantum computing applications" --num 5
exa-contents.js https://url1.com https://url2.com --highlights "practical uses"
exa-contents.js https://best-result.com --text
```

## Research Strategy

1. Break down the query into key search terms
2. Start with broad searches, then refine with specific terms
3. Use `--category` to target specific source types
4. Use date filters for recent information
5. Batch multiple URLs in single `exa-contents.js` calls
6. Use `exa-similar.js` to discover related content

## Reporting

When reporting findings:
- Organize by relevance and authority
- Include direct quotes with attribution
- Provide links to sources
- Note publication dates
- Highlight conflicting information
- Note gaps in available information
