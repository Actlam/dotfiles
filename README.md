# dotfiles

Lightweight dotfiles managed with [chezmoi](https://www.chezmoi.io/).

The goal of this repository is to make the terminal environment easy to restore
without making day-to-day configuration management complicated.

## Scope

Managed in v1:

- zsh
- git
- starship
- Ghostty
- WezTerm
- zsh-abbr
- GitHub CLI config without authentication files
- Homebrew packages through `Brewfile`

Not managed in v1:

- secrets, tokens, credentials
- `~/.ssh`
- GitHub CLI `hosts.yml`
- editor configs such as nvim, Zed, fish
- macOS defaults
- automatic 1Password injection
- automatic bootstrap scripts

## New Machine Setup

Install Xcode Command Line Tools:

```sh
xcode-select --install
```

Install Homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Install the minimum tools:

```sh
brew install ghq chezmoi
```

Clone and apply:

```sh
ghq get https://github.com/Actlam/dotfiles.git
chezmoi init --source ~/ghq/github.com/Actlam/dotfiles
chezmoi diff
chezmoi apply
brew bundle --file ~/ghq/github.com/Actlam/dotfiles/Brewfile
exec zsh
```

## Daily Use

Inspect local differences:

```sh
chezmoi diff
```

Add a changed file:

```sh
chezmoi add ~/.zshrc
```

Apply repository state to the machine:

```sh
chezmoi apply
```

Move to this repository:

```sh
chezmoi cd
```

Sync from another machine:

```sh
chezmoi cd
git pull
chezmoi diff
chezmoi apply
```

## Rules

- Keep this repository boring.
- Add tools after they stick, not while testing them.
- Never commit authentication files or secrets.
- Prefer a short README step over a clever script until the manual step becomes annoying.
