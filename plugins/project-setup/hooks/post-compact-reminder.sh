#!/usr/bin/env bash
# SessionStart(compact) stdout is added to Claude's context; point it at the handoff files.

project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"

echo "A context compaction just happened. Before continuing, rebuild the project invariants and the next execution step:"
if [ -f "$project_dir/HANDOFF.md" ]; then
  echo "- Read HANDOFF.md (your own handoff notes)."
else
  echo "- HANDOFF.md does not exist; say so instead of assuming earlier decisions."
fi
if [ -f "$project_dir/.claude/handoff-snapshot.md" ]; then
  echo "- Read .claude/handoff-snapshot.md (working-tree state captured right before compaction)."
fi
