# dotfiles

ターミナル環境を軽量に復元するための個人 dotfiles。管理は [chezmoi](https://www.chezmoi.io/)。

運用中の使い方(ユースケース別早見表)は [USAGE.md](./USAGE.md)。

## 方針

- ターミナル直結の設定だけ管理する
- zsh は標準形 (`~/.zshrc` / `~/.zshenv`) を使う。`ZDOTDIR` は使わない
- シークレット・token・認証情報は入れない
- 自動化より手数の少なさを優先する。`chezmoi diff` と `git status` で状態が分かる範囲に留める
- 新しいツールはまず手で試し、定着したら `Brewfile` に追加する

## 管理対象

入れているもの: zsh, git, starship, Ghostty, WezTerm, GitHub CLI 通常設定, Claude Code / Codex の共通指示, Herdrと各CLIのresume検索で共有する意味ベースセッションタイトル, Homebrew パッケージ一覧 (`Brewfile`), Zed のアプリインストール。

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
chezmoi init --source ~/ghq/github.com/Actlam/dotfiles  # git name/email と ghq root を聞かれる(既定 ~/ghq)
chezmoi diff && chezmoi apply

brew bundle --file ~/ghq/github.com/Actlam/dotfiles/Brewfile  # 必ず対話シェルで(後述)
mise install                                                  # ~/.config/mise/config.toml の通りに node / bun / 各 npm CLI を入れる
herdr integration install codex
herdr integration install claude

exec zsh
```

`chezmoi apply` は適用後に両integrationの状態を確認し、未導入またはHerdr本体より古いhookだけを自動更新する。
`/etc/zshenv` に `ZDOTDIR=$HOME/.config/zsh` が残っている Mac では、apply の前に `sudoedit /etc/zshenv` で該当行だけ削除する(`/etc/zshenv` 自体は残す)。

### 初回認証 (exec zsh 後の手動手順)

dotfiles に含めない方針(シークレット混入を避ける)のため、新マシン毎に手で実行する。

| 認証 | コマンド | 補足 |
|---|---|---|
| GitHub CLI | `gh auth login` | 既定は https プロトコル (`dot_config/gh/config.yml`)。SSH 鍵は不要 |
| Claude Code | `claude` を起動 | 初回起動でブラウザ認証 |
| Codex | `codex` を起動 | 同上 |
| Gemini CLI | `gemini` を起動 | 同上 |
| Atuin sync (任意) | `atuin login` | 履歴を別マシンと同期する場合のみ |
| SSH 鍵 (任意) | — | 通常運用は不要。ssh 強制リモートを使うときのみ別途設定 |

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
y                           # yazi (TUI ファイラー) を開く。終了時に最後にいたディレクトリへ自動 cd
mise use -g node@lts        # 言語ランタイム (node / bun / python / go ...) のグローバル指定
mise use -g npm:<package>   # グローバル npm CLI 追加。 ~/.config/mise/config.toml に追記される
mise install                # 設定ファイル通りに全部入れ直す (別マシン再現)
```

新しい CLI を `Brewfile` に足す時は `brew install` で試してから手で `brew "<name>"` を書く。`brew bundle dump --force` は使わない(余計なものが混ざる)。Brewfile に乗らない npm 系 CLI は `mise use -g npm:<name>` で入れる(`~/.config/mise/config.toml` に追記される)。

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
