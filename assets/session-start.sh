#!/bin/zsh
# SessionStart hook (added 2026-11-12, approved by the user).
# 1. Session started in a project folder -> open that folder in Finder (in the background).
# 2. Session started in ~ -> tell Claude to ask which project before writing anything.
# Skips headless sessions (`claude -p`, e.g. the cc queue), so queued tasks don't open windows.

input=$(cat)
source_kind=$(print -r -- "$input" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin).get("source",""))' 2>/dev/null)
cwd=$(print -r -- "$input" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null)
[[ -z "$cwd" ]] && cwd="$PWD"

# Headless runs: do nothing.
[[ "$CLAUDE_CODE_ENTRYPOINT" == sdk* ]] && exit 0
# Only on a fresh start or a resume, not after /clear or a compaction.
[[ "$source_kind" != "startup" && "$source_kind" != "resume" ]] && exit 0

if [[ "$cwd" == "$HOME" ]]; then
  reg="$HOME/.config/claude-launcher/projects.txt"
  projects=$(grep -v '^#' "$reg" 2>/dev/null | grep -v '^[[:space:]]*$' | grep -v $'\t~/scratch/' | cut -f1 | tr '\n' ' ')
  cat <<EOF
SESSION STARTED IN THE HOME FOLDER (~), NOT IN A PROJECT.
Before creating, writing or downloading any file, ask the user which project this belongs to,
then work only inside that project's folder (absolute paths). Never create files or folders directly in ~.
Registered projects (~/.config/claude-launcher/projects.txt): $projects
Pure questions and reading need no project. If nothing fits, propose a folder name and wait for their yes.
EOF
else
  open -g "$cwd" >/dev/null 2>&1
fi
exit 0
