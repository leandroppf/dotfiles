#!/usr/bin/env bash
# Create an ed25519 SSH key, load it into the agent and the macOS keychain, and
# write the ~/.ssh/config entry GitHub needs.
#
# Run this first on a new machine: without it `git clone git@github.com:...`
# fails and there is nothing obvious pointing at the missing key as the cause.
set -euo pipefail

KEY="$HOME/.ssh/id_ed25519"
EMAIL="${1:-leandroppf@gmail.com}"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$KEY" ]; then
  echo "Key already exists at $KEY — leaving it alone."
else
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY"
fi

eval "$(ssh-agent -s)" >/dev/null

# AddKeysToAgent/UseKeychain mean the passphrase is asked for once, ever.
if ! grep -qs "^Host github.com" "$HOME/.ssh/config"; then
  cat >> "$HOME/.ssh/config" <<'CONFIG'
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
CONFIG
  echo "Added github.com to ~/.ssh/config"
fi
chmod 600 "$HOME/.ssh/config"

ssh-add --apple-use-keychain "$KEY"

pbcopy < "$KEY.pub"
echo
echo "Public key copied to the clipboard. Add it at:"
echo "  https://github.com/settings/ssh/new"
echo "Then verify with: ssh -T git@github.com"
