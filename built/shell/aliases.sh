# Git aliases
alias s="git status"
alias d="git-local-diff"
alias hard="git reset --hard"
alias soft="git reset --soft HEAD~1"
alias co="git checkout"

alias wtb="~/Scripts/worktree-branch"
alias wto="~/Scripts/worktree-open"
alias wtor="~/Scripts/worktree-open --reset"
alias wtd="~/Scripts/worktree-purge"
alias wtc="~/Scripts/worktree-close"
alias wtl="eza --sort=modified --reverse --time=modified --long --no-user --no-permissions"
alias bdi="~/Scripts/bd-interactive"
alias log="git log --graph --decorate --pretty=format:'%h - %an, %ar : %s'"
alias ghdiff="~/Scripts/gh-diff"
alias prChecks='gh pr checks --watch'
alias bbdiff='open "$(git config remote.origin.url)/pull-requests/new#diff"'
alias auto-commit="~/Scripts/auto-commit"
alias auto-pr="~/Scripts/auto-pr"
alias auto-commit-pr="~/Scripts/auto-commit-pr"
alias ci='auto-commit'
alias pr='quick-pr'
alias pr-ai='auto-pr'
alias pr-diff='~/Scripts/git-pr-diff'
alias cipr='auto-commit-pr'
alias cip='~/Scripts/auto-commit-push'
alias pull="source ~/Scripts/git-pull"
alias push="source ~/Scripts/git-push"
alias fetch="source ~/Scripts/git-fetch"

add() {
  if [ $# -eq 0 ]; then
    git add .
  else
    git add "$@"
  fi
}

branch() {
  git checkout -b "$1"
}

branches() {
  git branch -a
}

resetTo() {
  target_branch="${1:-main}"
  git reset $(git merge-base origin/"$target_branch" $(git rev-parse --abbrev-ref origin/HEAD))
  git status
}

# app aliases
alias c="~/Scripts/cl"
alias v="nvim"
alias t="~/Scripts/tmux-start"
alias pi="~/Scripts/pi"
alias pnx="pnpm exec nx"
alias ls="~/Scripts/ls"
alias lso="/nix/store/iiishysy5bzkjrawxl4rld1s04qj0k0c-coreutils-9.8/bin/ls"
alias tree="ls --tree"
alias cato="/nix/store/iiishysy5bzkjrawxl4rld1s04qj0k0c-coreutils-9.8/bin/cat"
alias as="open -a \"Android Studio\""
alias vlc="/Applications/VLC.app/Contents/MacOS/VLC"
alias ett="et-with-tunnel"

alias sound="wiremix"
alias bluetooth="blueberry"
alias wifi="nmtui"
alias y='yazi'
if [[ -z "$IS_CLAUDE" ]]; then
  alias cat="bat"
fi

alias oc="opencode"
alias claude="cl"  # cl script adds session tracking for tmux
