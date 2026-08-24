#!/bin/sh

# Herdr owns these versioned hook scripts. Repair missing or outdated hooks
# after chezmoi has applied the surrounding Claude Code and Codex settings.
command -v herdr >/dev/null 2>&1 || exit 0

status="$(herdr integration status 2>/dev/null)" || exit 0

for agent in codex claude; do
  current="$(printf '%s\n' "$status" | sed -n "s/^${agent}: current .*/current/p")"
  if [ "$current" != "current" ]; then
    herdr integration install "$agent"
  fi
done
