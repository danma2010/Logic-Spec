#!/usr/bin/env bash
# install.sh [--no-claude] [--no-antigravity]
# Install or refresh Logic-Spec user-wide, so any design folder can use it.
# Re-run after every framework edit. Overwrites only the files it owns; never deletes.
#
#   rules  CLAUDE.md, AGENTS.md          -> ~/.logic-spec/            (loaded by each design's pointer files)
#   Claude Code   .claude/skills/fpga-*  -> ~/.claude/skills/         ($CLAUDE_CONFIG_DIR overrides ~/.claude)
#                 .claude/agents/fpga-*  -> ~/.claude/agents/
#   Antigravity   .agents/skills/fpga-*  -> ~/.gemini/antigravity/skills/   ($AG_SKILLS_DIR overrides)
#
# Every copy has {{LOGIC_SPEC}} replaced by this framework's absolute path.
# Runs tools/sync_agents.sh first so the Antigravity copy is current.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Windows (Git Bash/MSYS): use a C:/... path that Claude Code, Tcl and Python all accept
LS_PATH="$( (cd "$ROOT" && pwd -W) 2>/dev/null || echo "$ROOT")"

DO_CLAUDE=1; DO_AG=1
for a in "$@"; do case "$a" in
  --no-claude) DO_CLAUDE=0 ;;
  --no-antigravity) DO_AG=0 ;;
  *) echo "usage: install.sh [--no-claude] [--no-antigravity]"; exit 2 ;;
esac; done

LS_HOME="$HOME/.logic-spec"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
AG_SKILLS="${AG_SKILLS_DIR:-$HOME/.gemini/antigravity/skills}"

fill() { sed "s#{{LOGIC_SPEC}}#${LS_PATH}#g" "$1" > "$2"; }
copy_skills() {  # src_dir dst_dir
  local n=0
  for d in "$1"/fpga-*/; do
    local s; s="$(basename "$d")"
    mkdir -p "$2/$s"
    for f in "$d"*; do [ -f "$f" ] && fill "$f" "$2/$s/$(basename "$f")"; done
    n=$((n+1))
  done
  echo "  $n skills -> $2"
}

bash "$ROOT/tools/sync_agents.sh"

mkdir -p "$LS_HOME"
for r in CLAUDE.md AGENTS.md; do   # installed copy: drop the source-of-truth note, add a do-not-edit header
  { echo "<!-- Installed by $LS_PATH/tools/install.sh — edit the framework, not this copy. -->"
    awk 'c==0 && /^<!--/ {c=1} c==1 { if (/-->/) c=2; next } {print}' "$ROOT/$r"; } > "$LS_HOME/$r.tmp"
  fill "$LS_HOME/$r.tmp" "$LS_HOME/$r"; rm -f "$LS_HOME/$r.tmp"
done
echo "$LS_PATH" > "$LS_HOME/path"
echo "  rules -> $LS_HOME/{CLAUDE,AGENTS}.md   (framework: $LS_PATH)"

if [ "$DO_CLAUDE" = 1 ]; then
  copy_skills "$ROOT/.claude/skills" "$CLAUDE_DIR/skills"
  mkdir -p "$CLAUDE_DIR/agents"
  for f in "$ROOT"/.claude/agents/fpga-*.md; do fill "$f" "$CLAUDE_DIR/agents/$(basename "$f")"; done
  echo "  agents -> $CLAUDE_DIR/agents"
fi
[ "$DO_AG" = 1 ] && copy_skills "$ROOT/.agents/skills" "$AG_SKILLS"

echo "installed. New design:  bash $LS_PATH/tools/new_design.sh <folder>   (or open a folder and run fpga-spec)"
echo "note: a skill removed from the framework is not removed from the install folders — delete it there by hand."
