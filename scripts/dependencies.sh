#!/usr/bin/env bash
# Install Homebrew, the Brewfile, oh-my-zsh, and the zsh plugins/theme that
# oh-my-zsh does not bundle. Safe to re-run.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ── Homebrew ─────────────────────────────────────────────────────────────────
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "==> brew bundle"
brew bundle --file="$DOTFILES_DIR/Brewfile"

# ── oh-my-zsh ────────────────────────────────────────────────────────────────
# --unattended stops the installer from launching a shell and editing .zshrc,
# which would overwrite the one symlinked from this repo.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing oh-my-zsh"
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ── plugins and theme ────────────────────────────────────────────────────────
clone_if_missing() {
  local repo="$1" dest="$2"
  if [ -d "$dest" ]; then
    echo "  = $(basename "$dest")"
  else
    echo "  + $(basename "$dest")"
    git clone --depth=1 "$repo" "$dest"
  fi
}

echo "==> zsh plugins"
mkdir -p "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

echo "==> spaceship prompt"
# Installed from source rather than `brew install spaceship`: the brew formula
# expects you to source it from .zshrc, which combined with ZSH_THEME loads the
# prompt twice and renders it doubled.
clone_if_missing https://github.com/spaceship-prompt/spaceship-prompt \
  "$ZSH_CUSTOM/themes/spaceship-prompt"
ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" \
  "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

echo "Done."
