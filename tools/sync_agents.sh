#!/usr/bin/env bash
# sync_agents.sh — regenerate the Antigravity copy of the framework from the
# Claude Code source of truth, so the two platforms never drift.
#
#   CLAUDE.md                      -> AGENTS.md
#   .claude/skills/<s>/SKILL.md    -> .agents/skills/<s>/SKILL.md
#   .claude/agents/fpga-critic.md  -> .agents/skills/fpga-critic/SKILL.md
#
# .agents/rules/ is Antigravity-specific and left untouched.
# Never deletes anything. Run from anywhere:  bash tools/sync_agents.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# 1. rules
{
  echo "<!-- GENERATED from CLAUDE.md by tools/sync_agents.sh — do not edit here. -->"
  grep -v -e '^<!-- Single source of truth' -e '^     by tools/sync_agents.sh' CLAUDE.md
} > AGENTS.md

# 2. skills
for d in .claude/skills/*/; do
  s="$(basename "$d")"
  mkdir -p ".agents/skills/$s"
  sed 's/CLAUDE\.md/AGENTS.md/g' "$d/SKILL.md" > ".agents/skills/$s/SKILL.md"
done

# 3. critic: Claude subagent -> Antigravity skill (drop the Claude-only tools: line)
mkdir -p .agents/skills/fpga-critic
grep -v '^tools:' .claude/agents/fpga-critic.md | sed 's/CLAUDE\.md/AGENTS.md/g' > .agents/skills/fpga-critic/SKILL.md

echo "synced: AGENTS.md + $(ls -d .claude/skills/*/ | wc -l) skills + fpga-critic"
