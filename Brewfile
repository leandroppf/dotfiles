# Brewfile — install everything with: brew bundle --file=Brewfile
#
# Personal tools only. Language toolchains and SDKs that belong to a particular
# job are installed per-project, not here.

tap "oven-sh/bun"

# ── shell ────────────────────────────────────────────────────────────────────
brew "bat"              # cat with syntax highlighting (see .aliases)
brew "eza"              # modern ls (see .aliases)
brew "fzf"              # fuzzy finder; the oh-my-zsh fzf plugin wires up ^R and ^T
brew "aria2"            # parallel downloader

# ── cloud ───────────────────────────────────────────────────────────────────
brew "awscli"           # see docs/aws-mfa.md for the MFA workflow

# ── git ──────────────────────────────────────────────────────────────────────
brew "gh"               # GitHub CLI; also acts as the git credential helper
brew "git-lfs"

# ── runtimes ─────────────────────────────────────────────────────────────────
# Deliberately NOT installing the `node` formula: it puts a node on PATH that
# shadows fnm's shims, so .nvmrc switching stops working. Let fnm own node.
brew "fnm"              # node version manager
brew "rbenv"            # ruby version manager
brew "bun"              # javascript runtime / package manager

# ── writing ──────────────────────────────────────────────────────────────────
brew "markdownlint-cli"

# ── apps and fonts ───────────────────────────────────────────────────────────
cask "iterm2"
cask "font-fira-code"
cask "font-fira-code-nerd-font"   # the Nerd Font variant supplies the prompt glyphs
