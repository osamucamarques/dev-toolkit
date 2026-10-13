#!/usr/bin/env bash
# PreCompact cannot add text to Claude's context, so it records the working-tree
# state on disk for the post-compaction reminder to point at. Never blocks compaction.

project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
snapshot="$project_dir/.claude/handoff-snapshot.md"
trigger=$(grep -o '"trigger"[[:space:]]*:[[:space:]]*"[a-z]*"' | grep -o '[a-z]*"$' | tr -d '"')

mkdir -p "$project_dir/.claude" || exit 0
{
  echo "# Pre-compaction snapshot"
  echo
  echo "- Taken: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Trigger: ${trigger:-unknown}"
  if git -C "$project_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "- Branch: $(git -C "$project_dir" branch --show-current)"
    echo
    echo "## Uncommitted changes"
    echo
    echo '```'
    git -C "$project_dir" status --short
    git -C "$project_dir" diff --stat HEAD 2>/dev/null
    echo '```'
    echo
    echo "## Last commits"
    echo
    echo '```'
    git -C "$project_dir" log --oneline -5
    echo '```'
  fi
} > "$snapshot" 2>/dev/null

exit 0
