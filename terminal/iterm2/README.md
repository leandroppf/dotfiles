# iTerm2

These are set by hand rather than scripted. iTerm2 stores profiles as an array of
dictionaries inside `com.googlecode.iterm2.plist`, so writing them from a script
means indexing into that array with PlistBuddy — fragile, and it silently targets
the wrong profile when you have more than one. Four clicks is the better trade.

## Font

Settings ▸ Profiles ▸ Text

| Setting | Value |
|---|---|
| Font | FiraCode Nerd Font Mono, 12pt |
| Use a different font for non-ASCII text | ✅ enabled |
| Non-ASCII font | FiraCode Nerd Font Mono, 12pt |

Both fonts matter. The spaceship prompt draws its git/aws/node segments with
glyphs from the Private Use Area, which is non-ASCII — set only the first font
and those render as tofu boxes while ordinary text looks fine, which makes the
cause hard to spot.

`Brewfile` installs the font as `font-fira-code-nerd-font`. The plain
`font-fira-code` cask is the same typeface without the extra glyphs; it is
installed too, and it is *not* the one to select here.

## Shell integration

Nothing to install. The prompt comes from oh-my-zsh's `ZSH_THEME="spaceship"`,
configured in `~/.spaceshiprc.zsh`.
