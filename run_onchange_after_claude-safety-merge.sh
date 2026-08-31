#!/bin/bash
# Claude Code の安全設定を ~/.claude/settings.json へ冪等にマージする。
# settings.json はマシン固有のため全面管理せず、このスクリプトが所有する
# エントリ(git pushガードhook・permissions.deny)だけを追加・更新する。
# 2回実行しても重複しない。他のキー(UI設定・他のhooks・allow等)には触れない。
#
# guard script hash: dot_claude/hooks/executable_git-push-guard.sh の変更でも
# 再実行されるよう、chezmoi の run_onchange はこのファイル内容の変化を見る。
# ガードを更新したら下の VERSION を上げること。
# VERSION=2

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
GUARD_CMD='bash "$HOME/.claude/hooks/git-push-guard.sh"'

command -v jq >/dev/null || { echo "jq が必要です" >&2; exit 1; }

if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

cp "$SETTINGS" "$SETTINGS.bak"

tmp=$(mktemp)
jq --arg cmd "$GUARD_CMD" '
  # 1. git pushガード: 既存のguard参照エントリ(旧絶対パス含む)を除去して canonical を1つ追加
  .hooks //= {} |
  .hooks.PreToolUse //= [] |
  .hooks.PreToolUse |= map(select((.hooks // []) | any(.command // "" | test("git-push-guard\\.sh")) | not)) |
  .hooks.PreToolUse += [{"matcher": "Bash", "hooks": [{"type": "command", "command": $cmd}]}] |
  # 2. permissions.deny: 安全底の7件をマージ(既存は保持)
  .permissions //= {} |
  .permissions.deny //= [] |
  .permissions.deny = (.permissions.deny + [
    "Bash(rm -rf:*)",
    "Bash(git push --force:*)",
    "Bash(git push -f:*)",
    "Read(~/.ssh/**)",
    "Read(~/.aws/**)",
    "Read(**/.env*)",
    "Read(**/credentials*)"
  ] | unique) |
  # 3. AIツールの帰属表記を無効化(コミット・PRにツール名を残さない)
  .attribution = {"commit": "", "pr": ""}
' "$SETTINGS" > "$tmp"

# 構文検証してから反映
python3 -m json.tool "$tmp" > /dev/null
mv "$tmp" "$SETTINGS"
echo "claude-safety-merge: OK ($SETTINGS)"
