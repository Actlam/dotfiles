#!/bin/bash
# git-push-guard.sh
#
# PreToolUse hook (matcher: Bash). Warns when `git push` is invoked against
# master/main directly, with --force flags, or during the "本番反映禁止期間"
# (Fri / Sat / Sun). Always exits 0 — warning only, never blocks.
#
# 祝日および祝日前日の判定は省略しているので手動で意識すること。
#
# Scope: cosoji-jp/cosoji-client-v2 と cosoji-jp/cosoji-api のみ。
#        他リポでは何もせず即 exit。対象を増やすときは TARGET_REPOS に追記。
#
# Notion rule reference:
#   https://www.notion.so/Github-3449971f4bbc80c7964dd4d9e1599fdb

set -u

# 対象リポ (git remote.origin.url の部分一致)
TARGET_REPOS=(
  "cosoji-jp/cosoji-client-v2"
  "cosoji-jp/cosoji-api"
)

input="$(cat)"
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

# Quick exit: not a git push at all
if ! printf '%s' "$command" | grep -qE '(^|[ ;&|(])git[[:space:]]+push([[:space:]]|$|;|&|\|)'; then
  exit 0
fi

# Scope check: only run for target repos
remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")
in_scope=0
for repo in "${TARGET_REPOS[@]}"; do
  case "$remote_url" in
    *"$repo"*) in_scope=1; break ;;
  esac
done
if [ "$in_scope" = "0" ]; then
  exit 0
fi

warnings=()

# 1. Direct push to master / main
#    Matches: `... master`, `... main`, `... HEAD:master`, `... <ref>:main`
if printf '%s' "$command" | grep -qE 'git[[:space:]]+push.*([[:space:]:]|^)(master|main)([[:space:]:;&|]|$)'; then
  warnings+=("Notionルール: master/main への直 push は禁止です (PR + レビュー必須)")
fi

# 2. Force push detection (--force, --force-with-lease, --force-if-includes, -f)
force_detected=0
if printf '%s' "$command" | grep -qE 'git[[:space:]]+push.*--force'; then
  force_detected=1
fi
# Check `-f` as a standalone flag (word-boundary safe via space padding)
push_segment=$(printf '%s' "$command" | grep -oE 'git[[:space:]]+push[[:space:]]+[^;&|]*' | head -1)
if [ -n "$push_segment" ] && printf ' %s ' "$push_segment" | grep -qE '[[:space:]]-f([[:space:]]|$)'; then
  force_detected=1
fi

if [ "$force_detected" = "1" ]; then
  if printf '%s' "$command" | grep -qE '(master|main)'; then
    warnings+=("force push は master/main 禁止。作業ブランチのみで使ってください")
  else
    warnings+=("force push: 作業ブランチのみ可。意図したブランチか確認してください")
  fi
fi

# 3. 本番反映禁止期間 (金/土/日)
#    date +%u → 1=Mon, ..., 5=Fri, 6=Sat, 7=Sun
dow=$(date +%u)
case "$dow" in
  5) warnings+=("本日は金曜日。master へのマージは原則禁止 (本番反映禁止期間)") ;;
  6) warnings+=("本日は土曜日。master へのマージは原則禁止") ;;
  7) warnings+=("本日は日曜日。master へのマージは原則禁止") ;;
esac

# 4. Default reminder when no specific warning fired
if [ ${#warnings[@]} -eq 0 ]; then
  warnings+=("PR は Squash merge / 金曜・土日・祝前後は master マージ禁止")
fi

# Build message
msg="[git push ガード]"
for w in "${warnings[@]}"; do
  msg+=$'\n  - '"$w"
done

# Emit JSON: surface to user (systemMessage) AND to model (additionalContext)
jq -n --arg m "$msg" '{
  systemMessage: $m,
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $m
  }
}'

exit 0
