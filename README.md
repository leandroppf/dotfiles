# dotfiles

My macOS shell setup: zsh, oh-my-zsh, the spaceship prompt, and the handful of
CLI tools I expect to find on any machine I use.

Everything here is a personal preference. Read before running — the point of
dotfiles is that they suit one person.

## Install

```sh
git clone https://github.com/leandroppf/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

`install.sh` creates an SSH key and adds it to the keychain, installs Homebrew
and the `Brewfile`, installs oh-my-zsh with the plugins and theme it does not
bundle, then symlinks the config files into `$HOME`. It is safe to run again;
anything already in place is left alone, and a real file where a symlink should
go is moved to `<name>.backup-<timestamp>` rather than overwritten.

Then set the iTerm2 fonts by hand — see [`terminal/iterm2`](terminal/iterm2).

## What's inside

| | |
|---|---|
| `.zshrc` | oh-my-zsh, plugins, and the load order that makes completions work |
| `.zprofile` | Homebrew, fnm and rbenv initialisation |
| `.aliases` | `cat`→`bat`, `ls`→`eza` |
| `.exports` | environment variables |
| `.paths` | `PATH` entries |
| `.spaceshiprc.zsh` | prompt configuration |
| `.gitconfig`, `.gitignore_global` | git |
| `functions/` | shell functions, linked to `~/.zsh_functions` |
| `aws/` | annotated `~/.aws` templates (examples only, no real values) |
| `docs/` | longer-form notes |
| `Brewfile` | the CLI tools, fonts and apps |
| `scripts/` | the steps `install.sh` runs |

## AWS with enforced MFA

Accounts that require MFA reject long-lived access keys outright, so the CLI has
to trade them for a temporary MFA-backed session first. `awsmfa` does that in one
command, and `awsmfa_status` says how long is left:

```console
$ awsmfa
MFA code for your.name: 123456
awsmfa: [mfa] refreshed — expires 2026-08-24T22:13:41+00:00

$ awsmfa_status
awsmfa: [mfa] valid for 7h 41m (until 2026-08-24T22:13:41+00:00)
```

Full walkthrough, including the one-time IAM setup and the gotchas:
**[docs/aws-mfa.md](docs/aws-mfa.md)**.

## Machine-local configuration

`~/.zshrc.local` and `~/.zprofile.local` are sourced at the end of `.zshrc` and
`.zprofile` if they exist, and are never tracked. Anything that belongs to one
machine — a client's environment variables, a work-specific `PATH`, an
experiment — goes there. Nothing in this repository is secret, and nothing in it
should ever become secret.

## Notes to my future self

Three things that cost me an afternoon on this machine, now handled here:

- **`fpath` before `compinit`.** oh-my-zsh runs `compinit` inside
  `oh-my-zsh.sh`. Adding a completions directory to `fpath` *after* that line
  looks right and does nothing. `.zshrc` adds Homebrew's `site-functions` before
  the source line.
- **Let fnm own node.** The `node` Homebrew formula puts a binary on `PATH` that
  shadows fnm's shims, so `.nvmrc` switching stops working with no error. It is
  left out of the `Brewfile`, and `.zprofile` runs `fnm env --use-on-cd`, without
  which fnm does nothing at all in an interactive shell.
- **Install spaceship once.** Via `ZSH_THEME` only. `brew install spaceship` plus
  a `source` line in `.zshrc` loads it twice and the prompt renders doubled.

## Credits

Built by reading other people's, in this order:

- [rogerluan/dotfiles](https://github.com/rogerluan/dotfiles) — the structure
  this repo follows: modular shell files, a `Brewfile`, and one setup script
  orchestrating focused ones.
- [KrauseFx/dotfiles](https://github.com/KrauseFx/dotfiles) — the repo Roger
  credits, and a good argument for keeping this small.
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) — the
  `.aliases` / `.exports` / `.paths` split.

## License

MIT — see [LICENSE](LICENSE).
