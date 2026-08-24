# ~/.zprofile — login shells, read before ~/.zshrc.
#
# Version managers are initialised here rather than in .zshrc so the shims are
# on PATH exactly once per login shell instead of once per subshell.

# ── Homebrew ─────────────────────────────────────────────────────────────────
# Sets PATH, MANPATH, INFOPATH and FPATH for the Homebrew prefix.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── node, via fnm ────────────────────────────────────────────────────────────
# --use-on-cd switches automatically when a directory has .nvmrc/.node-version.
# Without this eval fnm is inert: `fnm use` does nothing to the running shell
# and every project silently gets whatever node is first on PATH.
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# ── ruby, via rbenv ──────────────────────────────────────────────────────────
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - --no-rehash zsh)"
fi

# ── machine-local overrides ──────────────────────────────────────────────────
[ -r "$HOME/.zprofile.local" ] && source "$HOME/.zprofile.local"
