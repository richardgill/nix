# Gmail CLI

Command-line interface for Gmail operations.

## Installation

```bash
npm install -g @mariozechner/gmcli
```

## Setup

### Google Cloud Console (one-time)

1. [Create a new project](https://console.cloud.google.com/projectcreate) (or select existing)
2. [Enable the Gmail API](https://console.cloud.google.com/apis/api/gmail.googleapis.com)
3. [Set app name](https://console.cloud.google.com/auth/branding) in OAuth branding
4. [Add test users](https://console.cloud.google.com/auth/audience) (all Gmail addresses you want to use)
5. [Create OAuth client](https://console.cloud.google.com/auth/clients):
   - Click "Create Client"
   - Application type: "Desktop app"
   - Download the JSON file

### Configure gmcli

First check if already configured:
```bash
gmcli accounts list
```

If no accounts, guide the user through setup:
1. Ask if they have a Google Cloud project with Gmail API enabled
2. If not, walk them through the Google Cloud Console steps above
3. Have them download the OAuth credentials JSON
4. Run: `gmcli accounts credentials ~/path/to/credentials.json`
5. Run: `gmcli accounts add <email>` (use `--manual` for browserless OAuth)

