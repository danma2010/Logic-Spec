#!/usr/bin/env bash
# new_design.sh <design_dir> [--template]
# Create (or complete) a Logic-Spec design project folder. Never overwrites:
#   <design>/spec/                 (--template: also spec/spec.md from the template)
#   <design>/CLAUDE.md, AGENTS.md  pointers to the framework rules in ~/.logic-spec/
#   <design>/.gitignore            tool-output ignores
# An existing CLAUDE.md / AGENTS.md / .gitignore gets the missing lines appended.
#
#   bash <LOGIC_SPEC>/tools/new_design.sh D:/work/my_ddc
set -euo pipefail
D="${1:?usage: new_design.sh <design_dir> [--template]}"
WITH_TPL="${2:-}"
LS="$(cd "$(dirname "$0")/.." && pwd)"
T="$LS/templates/design"
mkdir -p "$D/spec"
D="$(cd "$D" && pwd)"

add_pointer() {  # file, marker line, template
  local f="$1" marker="$2" tpl="$3"
  if [ ! -f "$f" ]; then cp "$tpl" "$f"; echo "created  $f"
  elif grep -qF "$marker" "$f"; then echo "ok       $f"
  else printf '\n' >> "$f"; cat "$tpl" >> "$f"; echo "appended $f"; fi
}
add_pointer "$D/CLAUDE.md" "@~/.logic-spec/CLAUDE.md" "$T/CLAUDE.md"
add_pointer "$D/AGENTS.md" "~/.logic-spec/AGENTS.md"  "$T/AGENTS.md"

if [ ! -f "$D/.gitignore" ]; then cp "$T/gitignore" "$D/.gitignore"; echo "created  $D/.gitignore"
else
  n=0; while IFS= read -r l; do
    [[ -z "$l" || "$l" == \#* ]] && continue
    grep -qxF "$l" "$D/.gitignore" || { echo "$l" >> "$D/.gitignore"; n=$((n+1)); }
  done < "$T/gitignore"; echo "ok       $D/.gitignore (+$n lines)"
fi

if [ -f "$D/spec/spec.md" ]; then echo "ok       $D/spec/spec.md"
elif [ "$WITH_TPL" = "--template" ]; then
  sed "s/<unit>/$(basename "$D")/" "$LS/templates/spec.md" > "$D/spec/spec.md"
  echo "created  $D/spec/spec.md  (template — write your requirements here)"
else echo "missing  $D/spec/spec.md  (write it, or describe the design to fpga-spec)"; fi

[ -f "$HOME/.logic-spec/CLAUDE.md" ] || echo "NOTE: ~/.logic-spec/ not found — run: bash $LS/tools/install.sh"
echo "design ready: $D   next: fpga-spec"
