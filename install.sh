#!/usr/bin/env bash
# Set up a Mac. Run from a clone of this repository:
#
#   git clone https://github.com/leandroppf/dotfiles.git ~/.dotfiles
#   ~/.dotfiles/install.sh
#
# Everything it calls is safe to run more than once.
set -euo pipefail

export DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "▶ SSH key"
"$DOTFILES_DIR/scripts/ssh_key.sh"

echo "▶ Dependencies"
"$DOTFILES_DIR/scripts/dependencies.sh"

echo "▶ Symlinks"
"$DOTFILES_DIR/scripts/symlinks.sh"

cat <<'NEXT'

Done. Open a new terminal tab, or run: exec zsh -l

Two things this repo deliberately does not do for you:
  • iTerm2 fonts — set both the ASCII and non-ASCII font to a Nerd Font
    (FiraCode Nerd Font Mono) in Settings ▸ Profiles ▸ Text, or the prompt
    glyphs render as boxes. See terminal/iterm2/README.md.
  • Machine-specific environment variables — put them in ~/.zshrc.local,
    which is never tracked.
NEXT
