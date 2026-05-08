# dotfiles

ターミナル環境を軽量に復元するための個人 dotfiles。chezmoi で管理している。

## 方針

ターミナル直結の設定だけ置く。シークレット・token・認証情報は混ぜない。zsh は `~/.zshrc` / `~/.zshenv` の標準形で動かしていて、`ZDOTDIR` は採らない。自動化は最低限、`chezmoi diff` と `git status` で状態が追える範囲に留める。新しいツールはまず手で試して、定着したら `Brewfile` に書き足す。

## 管理対象

入っているのは zsh, git, starship, Ghostty, WezTerm, GitHub CLI の通常設定、Claude Code / Codex の共通指示、Homebrew パッケージ一覧 (`Brewfile`)、それと Zed のアプリインストール。

`~/.ssh`、`~/.config/gh/hosts.yml`、`.env` / `.npmrc` / token / credentials、Zed の設定本体、nvim / fish、macOS defaults、bootstrap script、`ZDOTDIR` 運用は対象外。

詳細は各ファイルを直接見る。

## セットアップ

リポジトリは `~/ghq/github.com/Actlam/dotfiles` に置く前提。新規 Mac は Xcode CLT と Homebrew から。

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install ghq chezmoi
ghq get https://github.com/Actlam/dotfiles.git
chezmoi init --source ~/ghq/github.com/Actlam/dotfiles  # git name/email を聞かれる
chezmoi diff && chezmoi apply

brew bundle --file ~/ghq/github.com/Actlam/dotfiles/Brewfile  # 対話シェルから。理由は後述
volta install node@lts difit

exec zsh
```

`/etc/zshenv` に `ZDOTDIR=$HOME/.config/zsh` が残っている Mac だと、apply 前に `sudoedit /etc/zshenv` でその行だけ消す。ファイル自体は残す。

## 日常コマンド

```sh
chezmoi diff                # ホーム ↔ リポジトリの差分
chezmoi apply               # リポジトリ → ホームに反映
chezmoi add <path>          # ホーム側の変更を取り込む
chezmoi cd                  # リポジトリへ移動 (commit / push はここで)
chezmoi edit-config         # git name/email を変える ([data])
chezmoi managed             # 管理対象一覧
brew bundle --file Brewfile # 別マシンで Brewfile を反映
gwt [<branch>]              # worktree: 引数なしで一覧+切替 / 引数ありで <repo>/.worktrees/<branch> を作って cd
```

`Brewfile` に CLI を足すときは、`brew install` で試してから手で `brew "<name>"` を書く。`brew bundle dump --force` は余計なものが混ざるので使わない。Brewfile に乗らない npm 系 CLI は `volta install <name>` で入れる。

## シークレット

リポジトリに入れない: `~/.ssh`、`hosts.yml`、`.env`、`.npmrc`、`.netrc`、token、private key、credentials。

コミット前に一応見る。

```sh
git diff --cached --name-only
rg -n "token|secret|password|oauth|ghp_|gho_|github_pat|AKIA[0-9A-Z]{16}|BEGIN .*PRIVATE KEY"
```

## メモ

### `brew bundle` の cask install で `/Applications/<App>.app` が消える

`/Applications/` に手で入れてある WezTerm / Zed / Ghostty を brew が adopt するとき、内部で `sudo chmod -R a+rX` が走る。非対話シェルで叩くと sudo が通らず、brew はそのまま purge で `.app` を消す。実際に消えた。

対処は対話シェルで `brew bundle` を実行して sudo のパスワードを入れるだけ。

### 過去の失敗で残った dangling symlink で再 install が落ちる

```sh
ls -la /opt/homebrew/bin/zed
ls -la /opt/homebrew/bin/wezterm
ls -la /opt/homebrew/etc/bash_completion.d/wezterm
```

残っていたら `rm`(root 所有なら `sudo rm`)してから `brew install --cask <name>` をやり直す。
