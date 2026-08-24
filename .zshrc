# ~/.zshrc — interactive shell configuration.
#
# Load order matters here; see the compinit note below before moving anything.
# Machine-specific values do not belong in this file — use ~/.zshrc.local.

# ── oh-my-zsh ────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"

# spaceship is cloned into $ZSH_CUSTOM/themes by scripts/dependencies.sh and
# loaded by oh-my-zsh through this variable. Do NOT also `brew install spaceship`
# and source it from here: that loads the prompt twice and it renders doubled.
ZSH_THEME="spaceship"

# zsh-autosuggestions and zsh-syntax-highlighting are not bundled with oh-my-zsh;
# dependencies.sh clones them into $ZSH_CUSTOM/plugins.
plugins=(git aws fzf zsh-autosuggestions zsh-syntax-highlighting)

# Homebrew's completions (eza, bat, gh, ...). This MUST come before oh-my-zsh.sh:
# oh-my-zsh runs compinit, and any fpath entry added afterwards is never scanned.
# Homebrew only exposes this directory via `brew shellenv`, which we do not run.
if [ -d /opt/homebrew/share/zsh/site-functions ]; then
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi

# -U keeps these arrays deduplicated: .zprofile's `brew shellenv` adds the same
# site-functions directory, and a doubled fpath entry means a doubled compinit scan.
typeset -U path fpath

source "$ZSH/oh-my-zsh.sh"

# ── personal configuration ───────────────────────────────────────────────────
# Split the way mathiasbynens/dotfiles does, so each file stays readable.
for file in "$HOME/.paths" "$HOME/.exports" "$HOME/.aliases"; do
  [ -r "$file" ] && source "$file"
done
unset file

# Standalone shell functions, one per file.
for function_file in "$HOME/.zsh_functions"/*.zsh(N); do
  source "$function_file"
done
unset function_file

# ── machine-local overrides ──────────────────────────────────────────────────
# Never tracked. Anything that applies to one machine only — per-employer
# environment variables, client paths, experiments — belongs here.
[ -r "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
