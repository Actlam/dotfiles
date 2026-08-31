# 使い方ガイド

この dotfiles 環境で「何かしたいとき」に何を使うかの早見表。`README.md` がセットアップと方針を扱うのに対し、こちらは**運用中のユースケース**だけを置く。

## キーバインド早見表

| キー | 機能 | 担当 |
|---|---|---|
| `Ctrl+R` | 履歴の TUI 検索 | atuin |
| `→` | インライン補完(グレー)を確定 | zsh-autosuggestions |
| `Ctrl+T` | カレント以下のファイルを fzf | fzf + fd |
| `Alt+C` | カレント以下のディレクトリを fzf で選んで cd | fzf + fd |
| `Ctrl+]` | ghq 配下のリポジトリを fzf で選んで cd | 自作関数 |
| `Tab` | 補完(コマンド/ファイル/CLI 引数) | zsh + 各 CLI 自前補完 |

## ユースケース

### 1. 過去のコマンドをまた使いたい

| やりたいこと | 使うもの |
|---|---|
| 直前の同じコマンドの続きを書く | 入力始めて `→`(autosuggestions) |
| もっと前の履歴を絞り込んで探す | `Ctrl+R`(atuin TUI) |
| ↑ で前のコマンドに遡る | 矢印キー(atuin が入力済み文字でプレフィックス絞り込みした TUI を開く) |

### 2. ファイル/ディレクトリを探す・移動する

| やりたいこと | 使うもの |
|---|---|
| 過去の cd 先に飛ぶ | `cd <部分文字列>`(zoxide。`cd dot` で frecency 1 位) |
| frecency 上位を TUI で選ぶ | `cdi [<query>]`(zoxide の interactive。`--cmd cd` 指定で `cdi` も自動生成される) |
| カレント以下のファイル名検索 | `fd <pattern>` または `Ctrl+T` |
| カレント以下のディレクトリに移動 | `Alt+C` |
| コード内の文字列検索 | `rg <pattern>` |
| ghq 配下のリポジトリに飛ぶ | `Ctrl+]` |
| TUI で覗く・画像プレビュー | `y`(yazi。終了時に最終 dir へ自動 cd) |

`fd` / `rg` は `.gitignore` を尊重するので `node_modules` を踏まない。`find` / `grep` を直接使う場面はほぼ無い。

### 3. AI エージェントを並列で動かす

Claude Code / Codex / gemini-cli を**同時に複数走らせる**ときの定石。各エージェントを別 worktree に閉じ込めて衝突を避ける。

```sh
gwq add -b feature/agent-a    # ~/worktrees/<host>/<owner>/<repo>/feature/agent-a に新規 worktree
gwq cd feature/agent-a        # そこに cd(現在のシェルで切替、新シェルは起動しない)
claude                        # エージェント A をここで起動

# 別タブで:
gwq add -b feature/agent-b    # 別 worktree を作る
gwq cd feature/agent-b        # そっちに移動
codex                         # エージェント B

gwq list                      # 全 worktree 一覧
gwq remove feature/agent-a    # 終わった worktree を消す
```

`tmux` セッション内で `Claude Code Agent Teams` (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 設定済み)を使うと、1 つの Claude Code 内で複数エージェントを並列実行できる。tmux 前提。

### 4. PR / コードレビュー

| やりたいこと | コマンド |
|---|---|
| ローカルの作業差分を browser で見る | `difit`(タブを閉じるとサーバーも自動停止) |
| HEAD のコミットだけ見る | `difit HEAD` |
| main からの全差分 | `difit main HEAD` |
| GitHub の PR を見る | `difit --pr <PR URL>` |
| スクリプト用途/grep の比較 | 引き続き `git diff` |
| TUI で stage/commit/log | `lg`(lazygit) |

`git diff` の内部 pager は `git-delta` が自動で着色する(構造解析が要る時は別途 `difftastic` を併用してもよい)。

### 5. 言語ランタイムをプロジェクトごとに切り替える

```sh
cd ~/ghq/github.com/foo/bar
mise use node@22              # ./mise.toml に node = "22" が書かれる
# 以後そのリポジトリに入った瞬間、mise が自動で node@22 に切替
mise current                  # ここで何が active か
```

**AI エージェントがリポジトリ内でコマンドを叩くとき、mise.toml を見て正しい Node を使う**のがこの構成の主目的。逆に言うと、リポジトリに `mise.toml` を一度書けば、エージェントへの「このプロジェクトは Node 22 です」という指示が要らなくなる。

### 6. グローバル CLI を増やす

```sh
mise use -g npm:<package>     # ~/.config/mise/config.toml に追記され、即 PATH に乗る
mise use -g npm:<pkg>@<ver>   # バージョン固定
```

例: `mise use -g npm:typescript`

CLI を**消す**: `~/.config/mise/config.toml` から該当行を削除したうえで `mise uninstall npm:<pkg>` を打つ(`mise install` は不足分の install しかしないので、消えた行のバイナリは自動撤去されない)。

CLI を**更新**: `mise upgrade`(全部)または `mise upgrade npm:<pkg>`(個別)。設定で `latest` 指定にしているなら定期実行が運用の基本。`mise outdated` で更新可能なものを事前確認できる。

非 npm の CLI は backend を変える: `mise use -g cargo:<crate>` / `mise use -g pipx:<py-pkg>` / `mise use -g go:<pkg>` 等。

### 7. dotfiles を編集する

```sh
chezmoi cd                    # ~/ghq/github.com/Actlam/dotfiles へ移動
# 編集 → コミット → push
chezmoi diff                  # ホーム ↔ リポジトリの差分プレビュー
chezmoi apply                 # リポジトリ → ホームへ反映
chezmoi add <path>            # 手動で編集した家のファイルを取り込む
```

dotfiles を変更したら `exec zsh` で現セッションに反映する(reload しない限り旧 .zshrc のまま)。

#### エージェントの共通指示をPC間で共有する

`~/.agents/AGENTS.md` を共通指示の唯一の正本としてchezmoi管理する。Codexは `~/.codex/AGENTS.md` のsymlink、Claude Codeは `~/.claude/CLAUDE.md`、Gemini CLIは `~/.gemini/GEMINI.md` のimportから同じ内容を読み込む。

あるPCで内容を更新した場合は正本を編集し、通常のGitレビューを経て全PCへ反映する。ツール別の入口ファイルに共通指示を重複して書かない。

```sh
${EDITOR:-vi} ~/.agents/AGENTS.md
chezmoi diff ~/.agents/AGENTS.md
chezmoi add ~/.agents/AGENTS.md
chezmoi cd                    # commit / push / PR
```

別PCでは、マージ後に `chezmoi update` して各エージェントを新しく起動する。起動済みセッションへ確実に反映したい場合は再起動する。

### 8. ターミナル出力で困ったとき

| やりたいこと | コマンド |
|---|---|
| `cat <file>` がページャに食われる | 既に `cat` は `bat --paging=never` のエイリアス。別 alias で `bat` を直接呼ぶ手もある |
| `ls` の出力が icons 込みで PR 用 paste したい | `command ls`(eza alias を bypass) |
| 直前のコマンドのみ shell で見せたい | `which <cmd>`(関数の場合は本体表示)、`whence -p <cmd>`(実体パスのみ) |

## 落とし穴 / よくあるハマり

### `bun install -g` は使わない

グローバル CLI 配置は **mise に集約**してある(`~/.config/mise/config.toml`)。`bun install -g <pkg>` を打つと `~/.bun/bin` 配下に入って mise 管理から外れるので避ける。

プロジェクト用途の `bun install` / `bun add` / `bun run` はそのまま使ってよい(変化なし)。

### gwq の worktree 場所はリポジトリの**外**

旧 `gwt` 関数は `<repo>/.worktrees/<branch>` に置いていたが、`gwq` は `~/worktrees/<host>/<owner>/<repo>/<branch>`(ghq 構造ミラー)。リポジトリ内には出ない。

### `chezmoi apply` 後に `exec zsh` が要る

dotfiles を更新しても**現在のシェル**には反映されない。`exec zsh` で再読み込みすれば即反映。

### `brew bundle` は対話シェルで実行する

cask の adopt が `sudo` を要求する場合があり、非対話シェルだと sudo 失敗 →`/Applications/<App>.app` が消える事故になり得る(README ハマりどころ参照)。

### ターミナルは Ghostty 推奨

yazi の画像 / 動画 / PDF プレビューは **Kitty Graphics Protocol** 対応の端末 (Ghostty / WezTerm / kitty) でないと完全には機能しない。Alacritty や macOS 標準 Terminal では文字情報のみ。

### `/etc/zshenv` の `ZDOTDIR` は除去済みであること

旧設定の名残で `/etc/zshenv` に `ZDOTDIR=$HOME/.config/zsh` が残っていると、chezmoi 管理の `~/.zshrc` が読まれない(代わりに `~/.config/zsh/.zshenv` のブリッジが救うが、毎回それを通すのは無駄)。新規 Mac セットアップ時は `sudoedit /etc/zshenv` で該当行を消す。
