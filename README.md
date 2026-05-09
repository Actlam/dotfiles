# dotfiles

ターミナル環境を軽量に復元するための個人 dotfiles。管理は [chezmoi](https://www.chezmoi.io/)。

## 方針

- ターミナル直結の設定だけ管理する
- zsh は標準形 (`~/.zshrc` / `~/.zshenv`) を使う。`ZDOTDIR` は使わない
- シークレット・token・認証情報は入れない
- 自動化より手数の少なさを優先する。`chezmoi diff` と `git status` で状態が分かる範囲に留める
- 新しいツールはまず手で試し、定着したら `Brewfile` に追加する

## 管理対象

入れているもの: zsh, git, starship, Ghostty, WezTerm, GitHub CLI 通常設定, Claude Code / Codex の共通指示, Homebrew パッケージ一覧 (`Brewfile`), Zed のアプリインストール。

入れないもの: `~/.ssh`, `~/.config/gh/hosts.yml`, `.env` / `.npmrc` / token / credentials, Zed の設定本体, nvim / fish, macOS defaults, bootstrap script, `ZDOTDIR` 運用。

詳細は各ファイルを直接見る。

## セットアップ

このリポジトリは `~/ghq/github.com/Actlam/dotfiles` に置く前提。新規 Mac は最初に Xcode CLT と Homebrew を入れる。

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install ghq chezmoi
ghq get https://github.com/Actlam/dotfiles.git
chezmoi init --source ~/ghq/github.com/Actlam/dotfiles  # git name/email を聞かれる
chezmoi diff && chezmoi apply

brew bundle --file ~/ghq/github.com/Actlam/dotfiles/Brewfile  # 必ず対話シェルで(後述)
volta install node@lts difit

exec zsh
```

`/etc/zshenv` に `ZDOTDIR=$HOME/.config/zsh` が残っている Mac では、apply の前に `sudoedit /etc/zshenv` で該当行だけ削除する(`/etc/zshenv` 自体は残す)。

## 日常コマンド

```sh
chezmoi diff                # ホーム ↔ リポジトリの差分
chezmoi apply               # リポジトリ → ホームに反映
chezmoi add <path>          # ホーム側の変更を取り込む
chezmoi cd                  # リポジトリへ移動 (commit / push はここで)
chezmoi edit-config         # git name/email を変える ([data])
chezmoi managed             # 管理対象一覧
brew bundle --file Brewfile # 別マシンで Brewfile を反映
gwq list                    # worktree 一覧
gwq cd [<pattern>]          # worktree 切替 (fzf)。新シェルを起動せず現在のシェルで cd
gwq add -b <branch>         # 新規 worktree (~/worktrees/<host>/<owner>/<repo>/<branch> に展開)
```

新しい CLI を `Brewfile` に足す時は `brew install` で試してから手で `brew "<name>"` を書く。`brew bundle dump --force` は使わない(余計なものが混ざる)。Brewfile に乗らない npm 系 CLI は `volta install <name>` で入れる。

## シークレットを入れない

リポジトリに入れない: `~/.ssh`, `hosts.yml`, `.env`, `.npmrc`, `.netrc`, token / private key / credentials。

コミット前チェック:

```sh
git diff --cached --name-only
rg -n "token|secret|password|oauth|ghp_|gho_|github_pat|AKIA[0-9A-Z]{16}|BEGIN .*PRIVATE KEY"
```

## ハマりどころ

### `brew bundle` の cask install で `/Applications/<App>.app` が消える

既に `/Applications/` に手動で入った WezTerm / Zed / Ghostty を brew が adopt する際、内部で `sudo chmod -R a+rX` を走らせる。**非対話シェルで実行すると sudo が失敗 → brew が purge で `.app` ごと削除する**(実害あり)。

回避: `brew bundle` は対話シェルで実行し、sudo パスワードを入力する。

### 過去の失敗で残った dangling symlink で再 install が落ちる

```sh
ls -la /opt/homebrew/bin/zed
ls -la /opt/homebrew/bin/wezterm
ls -la /opt/homebrew/etc/bash_completion.d/wezterm
```

該当があれば `rm`(root 所有なら `sudo rm`)してから `brew install --cask <name>` を再実行。
