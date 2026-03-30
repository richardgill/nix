export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="nvim"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export BROWSER="tunnel-browser-open"
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=`which chromium`
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/.ripgreprc"

if [ "$(uname)" = "Darwin" ]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
fi

export PATH="$HOME/.mozbuild/git-cinnabar:$PATH"

export PATH="$PATH:$HOME/.local/bin"
export PATH="$HOME/.config/xata/bin:$PATH"
export PATH="$PATH:$HOME/code/reference-repos/web-search-exa"
export PATH="$HOME/Scripts/nixos:$HOME/Scripts:$PATH"

SECRETS_ENV_FILE="$HOME/.config/secrets/env.sh"
if [ -r "$SECRETS_ENV_FILE" ]; then
  . "$SECRETS_ENV_FILE"
fi
