# dotfiles

ターミナル環境を軽量に復元するための dotfiles です。

管理ツールは [chezmoi](https://www.chezmoi.io/) を使います。ただし、最初から複雑な自動化は入れず、「見れば分かる」「壊れても戻せる」ことを優先します。

## 方針

- まずはターミナル直結の設定だけ管理する
- zsh は標準形の `~/.zshrc` / `~/.zshenv` を使う
- シークレット、token、認証情報は絶対に入れない
- 新しいツールはまず手元で試し、使い続けるものだけ `Brewfile` に追加する
- 自動化より README の手順を優先する
- `chezmoi diff` と `git status` で状態が分かる範囲に留める

## 管理対象

v1 で管理しているもの:

- zsh: `.zshrc`, `.zshenv`
- git: `.gitconfig`, `.gitignore_global`
- starship
- Ghostty
- WezTerm
- Zed のアプリインストール
- GitHub CLI の通常設定: `~/.config/gh/config.yml`
- AI コーディングエージェント共通指示: `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`
- Homebrew パッケージ一覧: `Brewfile`

v1 では管理しないもの:

- `~/.ssh`
- `~/.config/gh/hosts.yml`
- `.env`, `.npmrc`, token, credentials
- Zed の設定ファイル
- nvim / fish
- zsh-abbr
- macOS defaults
- 1Password CLI による secret 注入
- 自動 bootstrap script
- `ZDOTDIR` による zsh 設定ディレクトリ変更

## 主要設定の要約

「自分が何を入れたっけ」をすぐ思い出すためのチートシート。詳細はファイルを開いて見ます。

| 領域 | 主な内容 | 場所 |
| --- | --- | --- |
| 環境変数 | XDG / `~/.local/bin` / Volta / Bun / `LANG=en_US.UTF-8` / `EDITOR=zed --wait` / PATH 重複排除 | `dot_zshenv` |
| 対話シェル | 履歴 10 万件 + share / 補完(大文字小文字無視, キャッシュ XDG 化) / starship・fzf・zoxide・atuin / eza・bat / git エイリアス (`gst` `gsw` `gbr` `gfe` `gpl` `gad` `gcm` `gmg` `gpsh`) / `Ctrl-]` で ghq+fzf | `dot_zshrc` |
| Git | name/email は chezmoi の `[data]` から差し込み / 共通 ignore あり | `dot_gitconfig.tmpl`, `dot_gitignore_global` |
| WezTerm | nord / JetBrains Mono Bold 13pt / opacity 0.93 / Leader=`Ctrl-,` / キーマップは `keybinds.lua` | `dot_config/wezterm/` |
| GitHub CLI | 通常設定のみ管理(認証情報の `hosts.yml` は対象外) | `dot_config/gh/config.yml` |
| AI agents | Claude Code / Codex の共通指示。差分レビュー時は `difit` を使う等 | `dot_claude/CLAUDE.md`, `dot_codex/AGENTS.md` |
| Brewfile | CLI: ghq, gh, chezmoi, volta, fzf, ripgrep, lazygit, starship, zoxide, atuin, bat, eza, git-delta, jq, yq, tmux / アプリ: Ghostty, WezTerm, Zed | `Brewfile` |
| Volta 経由で入れる CLI | difit(`volta install difit`) | README の「Volta で入れる CLI」 |

## 初期設定

### zsh の前提

この dotfiles では zsh の設定を標準の場所で管理します。

```text
~/.zshenv
~/.zshrc
```

`ZDOTDIR` で `~/.config/zsh` などへ移動する運用は使いません。既存マシンで `ZDOTDIR` を使っている場合は、`chezmoi apply` 前に現在の設定をバックアップしてから `ZDOTDIR` 設定を外します。

確認:

```sh
echo "$ZDOTDIR"
```

何も表示されない状態が標準です。

### 既存マシンで初めて使う

このリポジトリは `~/ghq/github.com/Actlam/dotfiles` に置く前提です。

```sh
brew install ghq chezmoi
ghq get https://github.com/Actlam/dotfiles.git
chezmoi init --source ~/ghq/github.com/Actlam/dotfiles
```

`chezmoi init` では Git の名前とメールアドレスを聞かれます。

反映前に必ず差分を確認します。

```sh
chezmoi diff
```

問題なければ反映します。

```sh
chezmoi apply
```

Homebrew のパッケージを入れます(エディタとして使う Zed もここで入ります)。

> ⚠️ 既に手動で WezTerm / Zed / Ghostty を `/Applications/` に入れている場合は、必ず**対話シェルで実行**してください。adopt のため sudo パスワードを聞かれます。詳細と復旧方法は「[Brewfile install のハマりどころ](#brewfile-install-のハマりどころ)」。

```sh
brew bundle --file ~/ghq/github.com/Actlam/dotfiles/Brewfile
```

Volta 経由の CLI を入れます(詳細は「[Volta で入れる CLI](#volta-で入れる-cli)」)。

```sh
volta install node@lts
volta install difit
```

新しい設定でシェルを開き直します。

```sh
exec zsh
```

### 旧 `~/.config/zsh` 運用から移行する

`/etc/zshenv` 等で `ZDOTDIR=$HOME/.config/zsh` が設定されていると、zsh は `~/.zshrc` ではなく `~/.config/zsh/.zshrc` を読みます。dotfiles の標準形とズレるので、移行前に解除します。

まずバックアップします。

```sh
mkdir -p ~/.dotfiles-backup
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.dotfiles-backup/zshrc.before-dotfiles
[ -f ~/.zshenv ] && cp ~/.zshenv ~/.dotfiles-backup/zshenv.before-dotfiles
[ -d ~/.config/zsh ] && cp -R ~/.config/zsh ~/.dotfiles-backup/config-zsh.before-dotfiles
```

次に `ZDOTDIR` を設定している箇所を外します。`/etc/zshenv` に書かれていることが多いです。ファイル全体を空にせず、`ZDOTDIR` を設定している行だけを削除します。

```sh
sudo cp /etc/zshenv /etc/zshenv.before-dotfiles
sudoedit /etc/zshenv
```

chezmoi の差分を確認して適用します(初回セットアップが済んでいない場合は「既存マシンで初めて使う」を先に実行してから戻ってきてください)。

```sh
chezmoi diff
chezmoi apply
exec zsh
```

確認:

```sh
echo "$ZDOTDIR"
echo "$HISTFILE"
git config --global --list
```

### 新しい Mac で復元する

Xcode Command Line Tools を入れます。

```sh
xcode-select --install
```

Homebrew を入れます。

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

最低限必要なツールを入れます。

```sh
brew install ghq chezmoi
```

dotfiles を取得して chezmoi を初期化します。

```sh
ghq get https://github.com/Actlam/dotfiles.git
chezmoi init --source ~/ghq/github.com/Actlam/dotfiles
```

反映内容を確認してから適用します。

```sh
chezmoi diff
chezmoi apply
```

Homebrew のパッケージを入れます。

```sh
brew bundle --file ~/ghq/github.com/Actlam/dotfiles/Brewfile
```

Volta 経由の CLI を入れます。

```sh
volta install node@lts
volta install difit
```

シェルを開き直します。

```sh
exec zsh
```

## Volta で入れる CLI

Brewfile に乗らない npm 系ツールは Volta でピン留めして入れます。「足していく」運用なので、増えたらここに追記します。

| ツール | 用途 | 入れ方 |
| --- | --- | --- |
| `difit` | GitHub 風 UI で git diff を見る Web ビューア。AI エージェントが diff レビュー時に使う | `volta install difit` |

Node が未インストールなら先に `volta install node@lts` を入れてください。

## Brewfile install のハマりどころ

cask(WezTerm / Zed / Ghostty)で `brew bundle install` がコケた時の対処メモ。

### 既に `/Applications/<App>.app` が手動で入っている場合

brew は既存 app を "adopt"(管理下に取り込み)しようとして `sudo chmod -R a+rX` を走らせます。**非対話シェルで実行すると sudo が失敗 → brew が purge で `/Applications/<App>.app` を削除します**(実害あり)。

回避策: 対話シェルで `brew bundle --file ~/ghq/github.com/Actlam/dotfiles/Brewfile` を走らせる。sudo パスワードを聞かれたら入力。

### 過去の失敗で残った dangling symlink で再インストールが失敗する場合

代表的な置き場:

```sh
ls -la /opt/homebrew/bin/zed                         # 削除済み Zed.app を指す
ls -la /opt/homebrew/bin/wezterm                     # 同上
ls -la /opt/homebrew/etc/bash_completion.d/wezterm   # 同上
```

該当があれば `rm` で消してから `brew install --cask <name>` を再実行します。`/usr/local/bin/zed` のように root 所有で残ることもあるので、その場合は `sudo rm`。

## 日常の更新方法

### ホーム側の設定変更をリポジトリに取り込む

例: `~/.zshrc` を編集した場合。

```sh
chezmoi diff
chezmoi add ~/.zshrc
chezmoi cd
git status
git add -A
git commit -m "Update zsh config"
git push
```

例: `~/.config/starship.toml` を編集した場合。

```sh
chezmoi add ~/.config/starship.toml
chezmoi cd
git diff --cached
git commit -m "Update starship config"
git push
```

### リポジトリ側の変更をホームに反映する

別マシンで更新した内容を反映する場合:

```sh
chezmoi cd
git pull
chezmoi diff
chezmoi apply
```

### chezmoi 管理対象を確認する

```sh
chezmoi managed
```

### まだ管理していないファイルを見る

```sh
chezmoi unmanaged ~ | head
```

大量に出るので、必要な時だけ確認します。

## Brewfile の更新

新しい CLI ツールを試す時は、まず普通に入れます。

```sh
brew install zoxide
```

しばらく使って「残す」と決めたら `Brewfile` に手で追加します。

```ruby
brew "zoxide"
```

その後、リポジトリにコミットします。

```sh
chezmoi cd
git add Brewfile
git commit -m "Add zoxide"
git push
```

別マシンでは次のコマンドで反映します。

```sh
brew bundle --file ~/ghq/github.com/Actlam/dotfiles/Brewfile
```

`brew bundle dump --force` は便利ですが、意図していないパッケージも入りやすいので、今の運用では基本的に使いません。

## Git の名前とメールを変える

chezmoi の設定ファイルを編集します。

```sh
chezmoi edit-config
```

`[data]` の `name` と `email` を変更します。

```toml
[data]
  email = "stream.actlam@gmail.com"
  name = "Actlam"
```

変更後に `.gitconfig` へ反映します。

```sh
chezmoi diff ~/.gitconfig
chezmoi apply ~/.gitconfig
git config --global user.email
```

## シークレットを入れないルール

以下はこのリポジトリに入れません。

- `~/.ssh`
- `~/.config/gh/hosts.yml`
- `.env`
- `.npmrc`
- `.netrc`
- token を含むファイル
- private key
- credentials

コミット前に最低限これを確認します。

```sh
git status
git diff --cached --name-only
```

不安な時は文字列検索します。

```sh
rg -n "token|secret|password|oauth|ghp_|gho_|github_pat|BEGIN .*PRIVATE KEY"
```

## よく使うコマンド

```sh
chezmoi diff       # ホームとリポジトリの差分を見る
chezmoi apply      # リポジトリの状態をホームに反映する
chezmoi add <path> # ホーム側の変更をリポジトリに取り込む
chezmoi cd         # dotfiles リポジトリに移動する
chezmoi managed    # 管理対象ファイルを見る
```

## 今後やるかもしれないこと

- repo path ごとの Git email 切り替え
- 1Password CLI を使った secret 注入
- yazi と関連ツールの追加
- Zed 設定の取り込み
- macOS defaults の管理
- bootstrap script の追加

必要になるまで追加しません。
