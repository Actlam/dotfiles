# dotfiles

ターミナル環境を軽量に復元するための dotfiles です。

管理ツールは [chezmoi](https://www.chezmoi.io/) を使います。ただし、最初から複雑な自動化は入れず、「見れば分かる」「壊れても戻せる」ことを優先します。

## 方針

- まずはターミナル直結の設定だけ管理する
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
- zsh-abbr
- GitHub CLI の通常設定: `~/.config/gh/config.yml`
- Homebrew パッケージ一覧: `Brewfile`

v1 では管理しないもの:

- `~/.ssh`
- `~/.config/gh/hosts.yml`
- `.env`, `.npmrc`, token, credentials
- nvim / Zed / fish
- macOS defaults
- 1Password CLI による secret 注入
- 自動 bootstrap script

## 初期設定

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
exec zsh
```

Homebrew のパッケージをまとめて入れる場合:

```sh
brew bundle --file ~/ghq/github.com/Actlam/dotfiles/Brewfile
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
exec zsh
```

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
- nvim / Zed の取り込み
- macOS defaults の管理
- bootstrap script の追加

必要になるまで追加しません。
