#!/usr/bin/env bash
# Link the tracked dotfiles into $HOME.
#
# Idempotent: re-running is a no-op for links that already point at this repo.
# A real file already sitting at the destination is moved aside, never clobbered.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STAMP="$(date +%Y%m%d%H%M%S)"

# source_in_repo:destination_in_home
LINKS=(
  ".zshrc:.zshrc"
  ".zprofile:.zprofile"
  ".aliases:.aliases"
  ".exports:.exports"
  ".paths:.paths"
  ".spaceshiprc.zsh:.spaceshiprc.zsh"
  ".gitconfig:.gitconfig"
  ".gitignore_global:.gitignore_global"
  "functions:.zsh_functions"
)

link() {
  local src="$DOTFILES_DIR/$1" dest="$HOME/$2"

  if [ ! -e "$src" ]; then
    echo "  ✗ missing in repo: $1" >&2
    return 1
  fi

  # Already pointing where we want it — nothing to do.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  = $2"
    return 0
  fi

  # A real file (or a link somewhere else) is in the way: preserve it.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.backup-$STAMP"
    echo "  ~ $2 -> backed up as $2.backup-$STAMP"
  fi

  ln -s "$src" "$dest"
  echo "  + $2"
}

echo "Linking dotfiles from $DOTFILES_DIR"
for entry in "${LINKS[@]}"; do
  link "${entry%%:*}" "${entry##*:}"
done
echo "Done."
