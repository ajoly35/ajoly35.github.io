#!/bin/zsh
# Research & organisation kit — one-paste installer (generated 2026-11-04).
# Writes the kit into ~/claude-kit, then runs its install.sh. Read it before running: everything it does is here.
set -e
T="$HOME/claude-kit"; mkdir -p "$T"
echo "→ writing kit files to $T"
true
cat > "$T/README.md" <<'KIT_EOF_0'
# Kit Claude — dicter, trier, exécuter

Ce kit installe sur un Mac la chaîne décrite dans le brief « Comment j'utilise Claude au quotidien » :
une note par jour → `cc inbox` → agenda / rappels / sessions de travail Claude Code ; `cc memo` pour le point
hebdomadaire ; « Accentuer » pour les accents d'un clic droit.

## Prérequis (10 min)
1. Un compte Claude (Pro ou Max) et l'application Claude pour Mac.
2. Claude Code installé ; lancer `claude` une fois dans un terminal pour se connecter.
3. Homebrew (https://brew.sh).

## Installation (5 min)
```
unzip claude-kit.zip && cd claude-kit && zsh install.sh
```
Ouvrir un nouveau terminal : `cc ls` doit afficher `scratch`.

## Premier usage
- Dans Notes, créer une note « to dos <date du jour> » avec trois lignes : un rendez-vous (« appel X jeudi 15h »),
  une relance (« envoyer le dossier à Y demain »), un sujet de fond (« préparer un script de 45 s sur … »).
- `cc inbox` → macOS demande les autorisations Notes, Calendrier, Rappels : accepter. Choisir le calendrier et la liste.
- Le rendez-vous est dans l'agenda, la relance dans Rappels, le sujet est ouvert dans une session Claude.
- `Ctrl-b d` détache la session (elle continue) ; `cc` pour y revenir.

## Vos projets
Dans chaque dossier de travail : `cd` dedans, `cc add`, puis dans la session Claude : « écris le CLAUDE.md de ce
projet : ce que c'est, où sont les sources, les règles ». Dès lors `cc <nom>` ouvre le projet avec son contexte.

## Chaque semaine
`cc memo` compile le journal des sessions en point hebdomadaire ; `cc memo --message` en tire le message WhatsApp
(demandes nominatives et datées, copié dans le presse-papiers) et les relances à coller dans la note du jour.

## Commandes
```
cc                 choisir un projet, reprendre sa session
cc <nom> -c        reprendre la dernière conversation
cc new <nom>       nouveau projet dans ~/scratch
cc today           lancer les sujets de la note du jour
cc inbox           trier la note du jour : agenda / rappels / sessions
cc memo            point hebdomadaire ;  cc memo --message  → message WhatsApp
cc ls / cc add     registre des projets
```
Fichiers : `~/.config/claude-launcher/` (lanceur, scripts, `projects.txt`, `ledger/`), `~/scratch/`, `~/Library/Services/`.
Réglages VS Code recommandés : `~/.config/claude-launcher/vscode_settings_snippet.json`.

## Si ça bloque
Ouvrir une conversation Claude dans l'application Mac, autoriser le dossier d'accueil, et dire :
« finis l'installation du kit Claude qui est dans ~/Téléchargements/claude-kit ».
KIT_EOF_0
true
cat > "$T/install.sh" <<'KIT_EOF_1'
#!/bin/zsh
# Installation du kit Claude (lanceur cc, Notes → agenda/rappels/terminal, mémo, actions rapides). Idempotent.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
L="$HOME/.config/claude-launcher"
echo "→ lanceur dans $L"
mkdir -p "$L/ledger"
cp "$HERE"/launcher/{cc.zsh,notes_ideas.py,inbox.py,memo.py,cockpit.py,comms.py,accentuer.sh,launch-idea.sh,queue-runner.zsh,com.cc-queue.plist,vscode_settings_snippet.json} "$L/"
[[ -f "$L/projects.txt" ]] || cp "$HERE/launcher/projects.txt" "$L/"
chmod +x "$L"/*.sh "$L"/*.py
echo "→ dossier scratch et modèle de projet"
mkdir -p "$HOME/scratch/.template" "$HOME/scratch/.memo"
cp "$HERE/template/CLAUDE.md" "$HOME/scratch/.template/CLAUDE.md"
[[ -f "$HOME/scratch/CLAUDE.md" ]] || cp "$HERE/template/scratch-CLAUDE.md" "$HOME/scratch/CLAUDE.md"
echo "→ actions rapides (Services)"
mkdir -p "$HOME/Library/Services"
cp -R "$HERE"/services/*.workflow "$HOME/Library/Services/"
/System/Library/CoreServices/pbs -update 2>/dev/null || true
echo "→ tmux"
[[ -f "$HOME/.tmux.conf" ]] || cp "$HERE/launcher/tmux.conf" "$HOME/.tmux.conf"
if command -v brew >/dev/null 2>&1; then
  brew list tmux >/dev/null 2>&1 || brew install tmux
  brew list fzf  >/dev/null 2>&1 || brew install fzf
else
  echo "   Homebrew absent : installez-le (https://brew.sh) puis : brew install tmux fzf"
fi
echo "→ .zshrc"
grep -q 'claude-launcher/cc.zsh' "$HOME/.zshrc" 2>/dev/null || printf '\n# Claude launcher\nsource ~/.config/claude-launcher/cc.zsh\n' >> "$HOME/.zshrc"
if ! command -v claude >/dev/null 2>&1; then
  echo "   Claude Code n'est pas installé : voir https://docs.claude.com/en/docs/claude-code/overview, puis lancez 'claude' une fois."
fi
echo
echo "Terminé. Ouvrez un nouveau terminal puis :  cc ls"
echo "Mode d'emploi : $HERE/README.md"
echo "→ file d'attente (queue runner, toutes les 60 s)"
mkdir -p "$HOME/scratch/.queue/done" "$HOME/Library/LaunchAgents"
sed "s|\$HOME|$HOME|g" "$L/com.cc-queue.plist" > "$HOME/Library/LaunchAgents/com.cc-queue.plist"
launchctl unload "$HOME/Library/LaunchAgents/com.cc-queue.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.cc-queue.plist" 2>/dev/null && echo "   queue runner chargé"
KIT_EOF_1
mkdir -p "$T/launcher"
cat > "$T/launcher/accentuer.sh" <<'KIT_EOF_2'
#!/bin/zsh
# Fix French accents/punctuation in text (stdin or $1) using claude -p. Used by the "Accentuer" Quick Action.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
text="${1:-$(cat)}"
[[ -z "$text" ]] && exit 0
claude -p "Corrige uniquement les accents, cédilles, apostrophes et espaces de ponctuation française dans le texte ci-dessous. Ne reformule rien, ne change aucun mot, garde la mise en forme et les retours à la ligne. Réponds avec le texte corrigé seulement, sans commentaire ni guillemets.

$text" 2>/dev/null || print -r -- "$text"
KIT_EOF_2
mkdir -p "$T/launcher"
cat > "$T/launcher/cc.zsh" <<'KIT_EOF_3'
# cc — one-keystroke Claude Code launcher
# Source this from ~/.zshrc:   source ~/.config/claude-launcher/cc.zsh
#
#   cc                 pick a project (fzf), open/attach its tmux session, start claude
#   cc <name>          same, by name (prefix match ok)
#   cc <name> -c       pass flags through to claude (e.g. -c / --resume)
#   cc new <name>      create ~/scratch/<name> from the template, register it, launch
#   cc add [name]      register the current directory
#   cc ls              list registered projects (* = tmux session running)
#   cc kill <name>     kill that project's tmux session
#   cc x               quick: launch claude in the current directory (no tmux)
#   cc idea            pick a to-do from the "Ideas" note in Apple Notes → new scratch project,
#                      claude opens with the idea as first prompt, the line gets ✅ in Notes
#   cc idea "text"     same, from text (used by the Shortcut / Services menu)
#   cc today           find today's note (date in title, else created/modified today) → same flow;
#                      runs straight away if there is a single open line
#   cc inbox           classify today's note lines → tasks launched here, events → Calendar,
#                      reminders → Reminders; shows the plan and asks before doing anything
#   cc inbox --auto    same, but every task goes to the queue runner (detached, autonomous) — nothing to attach
#   cc run [P1]        launch every open cockpit task (optionally only P1) through the queue, detached
#   cc cockpit         rebuild and show ~/scratch/COCKPIT.md (tasks, sessions, journal, queue)
#   cc memo            draft this week's group memo from the ledger + project logs + git, opens it
#   cc queue "text"    drop a task for the queue runner (runs within a minute, detached) — same as from the phone
#   cc idea --notes    list note titles, to find the right one
#   CC_NOTE="Other"    use a different note title (export in ~/.zshrc)

CC_REGISTRY="${CC_REGISTRY:-$HOME/.config/claude-launcher/projects.txt}"
CC_NOTES_PY="${CC_NOTES_PY:-$HOME/.config/claude-launcher/notes_ideas.py}"
CC_INBOX_PY="${CC_INBOX_PY:-$HOME/.config/claude-launcher/inbox.py}"
CC_MEMO_PY="${CC_MEMO_PY:-$HOME/.config/claude-launcher/memo.py}"
CC_COCKPIT_PY="${CC_COCKPIT_PY:-$HOME/.config/claude-launcher/cockpit.py}"
CC_SCRATCH="${CC_SCRATCH:-$HOME/scratch}"
CC_TEMPLATE="${CC_TEMPLATE:-$CC_SCRATCH/.template}"

_cc_entries() { grep -v '^[[:space:]]*#' "$CC_REGISTRY" | grep -v '^[[:space:]]*$'; }
_cc_names()   { _cc_entries | cut -f1; }
_cc_expand()  { local p="$1"; print -r -- "${p/#\~/$HOME}"; }

_cc_path_for() {
  local n="$1" line
  line=$(_cc_entries | awk -F'\t' -v n="$n" '$1==n{print; exit}')
  [[ -z "$line" ]] && line=$(_cc_entries | awk -F'\t' -v n="$n" 'index($1,n)==1{print; exit}')
  [[ -z "$line" ]] && return 1
  _cc_expand "${line#*$'\t'}"
}

_cc_pick() {
  if command -v fzf >/dev/null 2>&1; then
    local sel
    sel=$(_cc_entries | fzf --delimiter=$'\t' --with-nth=1 --prompt='project > ' --height=40% --reverse) || return 1
    _cc_expand "${sel#*$'\t'}"
  else
    local names; names=("${(@f)$(_cc_names)}")
    local n; select n in "${names[@]}"; do [[ -n "$n" ]] && { _cc_path_for "$n"; return; }; done
  fi
}

_cc_session_name() { basename "$1" | tr -c 'A-Za-z0-9_-' '-' | sed 's/-*$//' }

_cc_launch() {
  local dir="$1"; shift
  [[ -d "$dir" ]] || { echo "cc: no such directory: $dir" >&2; return 1; }
  if ! command -v tmux >/dev/null 2>&1; then
    cd "$dir" && claude "$@"; return
  fi
  local sess; sess=$(_cc_session_name "$dir")
  if ! tmux has-session -t "=$sess" 2>/dev/null; then
    tmux new-session -d -s "$sess" -c "$dir"
    tmux send-keys -t "=$sess" "claude $*" Enter
  fi
  if [[ -n "$CC_NO_ATTACH" ]]; then echo "started: $sess"; return; fi   # batch mode (cc inbox / cc today with several lines)
  if [[ -n "$TMUX" ]]; then tmux switch-client -t "=$sess"; else tmux attach-session -t "=$sess"; fi
}

# attach to a session by name (after a batch)
_cc_attach() {
  if [[ -n "$TMUX" ]]; then tmux switch-client -t "=$1"; else tmux attach-session -t "=$1"; fi
}

# create a scratch project: _cc_create <name> [idea text]
_cc_create() {
  local n="$1" idea="$2" d="$CC_SCRATCH/$1"
  [[ -e "$d" ]] && { echo "cc: $d exists" >&2; return 1; }
  mkdir -p "$d/data/raw" "$d/data/derived" "$d/output" "$d/notes" "$d/scripts"
  if [[ -f "$CC_TEMPLATE/CLAUDE.md" ]]; then
    sed "s/{{NAME}}/$n/g; s/{{DATE}}/$(date +%Y-%m-%d)/g" "$CC_TEMPLATE/CLAUDE.md" > "$d/CLAUDE.md"
    if [[ -n "$idea" ]]; then
      IDEA="$idea" perl -0pi -e 's/(## What this is\n)<!--.*?-->\n/$1$ENV{IDEA}\n/s' "$d/CLAUDE.md"
    fi
  fi
  [[ -n "$idea" ]] && printf -- '- %s: created from idea: %s\n' "$(date +%Y-%m-%d)" "$idea" > "$d/notes/log.md"
  (cd "$d" && git init -q 2>/dev/null)
  printf '%s\t%s\n' "$n" "${d/#$HOME/~}" >> "$CC_REGISTRY"
  echo "created $d"
}

# pick one line out of a newline-separated list (fzf if available)
_cc_pick_line() {
  local lines="$1" prompt="$2"
  if command -v fzf >/dev/null 2>&1; then
    print -r -- "$lines" | fzf --prompt="$prompt" --height=40% --reverse
  else
    local opts o; opts=("${(@f)lines}")
    select o in "${opts[@]}"; do [[ -n "$o" ]] && { print -r -- "$o"; return; }; done
    return 1
  fi
}

# turn a to-do line into a scratch project and launch claude on it: _cc_from_text <note title or ""> <text>
_cc_from_text() {
  local title="$1" text="$2"
  [[ -z "$text" ]] && return 1
  local n; n=$(python3 "$CC_NOTES_PY" slug "$text")
  [[ -e "$CC_SCRATCH/$n" ]] && n="$n-$(date +%m%d-%H%M)"
  _cc_create "$n" "$text" || return 1
  if [[ -n "$title" ]]; then
    python3 "$CC_NOTES_PY" mark --note "$title" "${text%% — *}" 2>/dev/null || echo "(couldn't tick the line in Notes — left as is)"
  fi
  local prompt="New task from my notes: ${text}. Read CLAUDE.md, rewrite the 'What this is' section in your own words, then propose a short plan (3-5 steps) and wait for my go before executing."
  if [[ -n "$CC_COCKPIT_ID" ]]; then
    python3 "$CC_COCKPIT_PY" start "$CC_COCKPIT_ID" --session "$(_cc_session_name "$CC_SCRATCH/$n")" >/dev/null
    print -r -- "- cockpit id: $CC_COCKPIT_ID" >> "$CC_SCRATCH/$n/notes/log.md"
  fi
  _cc_launch "$CC_SCRATCH/$n" "${(q)prompt}"
}

cc() {
  local cmd="$1"
  case "$cmd" in
    "")   local d; d=$(_cc_pick) || return; _cc_launch "$d" ;;
    x)    shift; claude "$@" ;;
    ls)
      local line n p s
      _cc_entries | while IFS=$'\t' read -r n p; do
        s=$(_cc_session_name "$(_cc_expand "$p")")
        if tmux has-session -t "=$s" 2>/dev/null; then printf '* %-22s %s\n' "$n" "$p"; else printf '  %-22s %s\n' "$n" "$p"; fi
      done ;;
    add)
      local n="${2:-$(basename "$PWD")}" p="${PWD/#$HOME/~}"
      _cc_names | grep -qx "$n" && { echo "cc: '$n' already registered" >&2; return 1; }
      printf '%s\t%s\n' "$n" "$p" >> "$CC_REGISTRY"; echo "registered $n -> $p" ;;
    new)
      local n="$2"; [[ -z "$n" ]] && { echo "usage: cc new <name>" >&2; return 1; }
      _cc_create "$n" "" || return 1
      shift 2; _cc_launch "$CC_SCRATCH/$n" "$@" ;;
    idea)
      shift
      if [[ "$1" == "--notes" ]]; then python3 "$CC_NOTES_PY" notes; return; fi
      if [[ -n "$1" ]]; then _cc_from_text "" "$*"; return; fi
      local lines; lines=$(python3 "$CC_NOTES_PY" list) || return 1
      [[ -z "$lines" ]] && { echo "cc: no open to-dos in note '${CC_NOTE:-Ideas}'" >&2; return 1; }
      local text; text=$(_cc_pick_line "$lines" 'idea > ') || return
      _cc_from_text "${CC_NOTE:-Ideas}" "$text" ;;
    today)
      shift
      local out; out=$(python3 "$CC_NOTES_PY" today) || return 1
      local title="${out%%$'\n'*}" lines="${out#*$'\n'}"
      [[ "$out" == "$title" ]] && lines=""
      [[ -z "$lines" ]] && { echo "cc: today's note is '$title' but it has no open to-dos" >&2; return 1; }
      echo "today's note: $title"
      local text
      if [[ "$lines" != *$'\n'* ]]; then
        text="$lines"                       # single line: no need to ask
      else
        text=$(_cc_pick_line "$lines" 'today > ') || return
      fi
      _cc_from_text "$title" "$text" ;;
    inbox)
      shift
      local auto=""; [[ "$1" == "--auto" ]] && { auto=1; shift; }
      local title; title=$(python3 "$CC_NOTES_PY" today-note) || return 1
      local tasks; tasks=$(python3 "$CC_INBOX_PY" run "$@") || return 1
      [[ -z "$tasks" ]] && return 0
      local line tid tp text first=""
      for line in "${(@f)tasks}"; do
        [[ -z "$line" ]] && continue
        tid="${line%%$'\t'*}"; text="${line##*$'\t'}"; tp="${${line#*$'\t'}%%$'\t'*}"
        if [[ -n "$auto" ]]; then
          mkdir -p "$CC_SCRATCH/.queue"; printf '%s\n' "$text" > "$CC_SCRATCH/.queue/$tid.task"
          python3 "$CC_NOTES_PY" mark --note "$title" "${text%% — *}" >/dev/null 2>&1
          echo "queued [$tp] $tid: ${text%% — *}"
        else
          CC_COCKPIT_ID="$tid" CC_NO_ATTACH=1 _cc_from_text "$title" "$text"
          [[ -z "$first" ]] && first=$(_cc_session_name "$CC_SCRATCH/$(python3 "$CC_NOTES_PY" slug "$text")")
        fi
      done
      python3 "$CC_COCKPIT_PY" refresh >/dev/null
      if [[ -n "$auto" ]]; then echo "the queue runner starts them within a minute; cc cockpit to follow"; return; fi
      echo; cc ls | grep '^\*'; echo "(Option+←/→ to switch, Ctrl-b d to detach)"
      [[ -n "$first" ]] && tmux has-session -t "=$first" 2>/dev/null && _cc_attach "$first" ;;
    run)
      shift; local p="$1"; mkdir -p "$CC_SCRATCH/.queue"
      local line tid tp text n=0
      for line in "${(@f)$(python3 "$CC_COCKPIT_PY" next ${p:+--p $p})}"; do
        [[ -z "$line" ]] && continue
        tid="${line%%$'\t'*}"; text="${line##*$'\t'}"
        printf '%s\n' "$text" > "$CC_SCRATCH/.queue/$tid.task"; python3 "$CC_COCKPIT_PY" start "$tid" --session queued; n=$((n+1))
      done
      python3 "$CC_COCKPIT_PY" refresh >/dev/null; echo "queued $n task(s); the runner starts them within a minute" ;;
    cockpit)
      python3 "$CC_COCKPIT_PY" refresh >/dev/null; cat "$CC_SCRATCH/COCKPIT.md" ;;
    memo)
      shift; python3 "$CC_MEMO_PY" "$@" ;;
    queue)
      shift; mkdir -p "$CC_SCRATCH/.queue"
      [[ "$1" == "inbox" ]] && { touch "$CC_SCRATCH/.queue/INBOX"; echo "queued: inbox"; return; }
      print -r -- "$*" > "$CC_SCRATCH/.queue/$(date +%s).task"; echo "queued: $*" ;;
    kill)
      local d; d=$(_cc_path_for "$2") || { echo "cc: unknown project '$2'" >&2; return 1; }
      tmux kill-session -t "=$(_cc_session_name "$d")" ;;
    help|-h|--help) sed -n '2,25p' "${(%):-%x}" ;;
    *)
      local d; d=$(_cc_path_for "$cmd") || { echo "cc: unknown project '$cmd' (try: cc ls)" >&2; return 1; }
      shift; _cc_launch "$d" "$@" ;;
  esac
}

# tab completion for project names
if (( $+functions[compdef] )); then
  _cc() { local -a names; names=(new idea today inbox run cockpit memo queue add ls kill x "${(@f)$(_cc_names)}"); _describe 'project' names; }
  compdef _cc cc
fi
KIT_EOF_3
mkdir -p "$T/launcher"
cat > "$T/launcher/cockpit.py" <<'KIT_EOF_4'
#!/usr/bin/env python3
"""cockpit.py — the local source of truth for everything in flight, rebuilt as ~/scratch/COCKPIT.md.

  cockpit.py add  --p P1|P2|P3 --text "..." [--project NAME] [--link URL] [--source inbox]   add a task
  cockpit.py start  <id> [--session NAME]      mark running (done by cc / queue runner)
  cockpit.py done   <id> [--note "..."]        mark done
  cockpit.py wait   --text "..."               add an item to "En attente de toi"
  cockpit.py unwait <id>
  cockpit.py refresh                           rebuild COCKPIT.md from tasks + tmux + ledger + queue log
  cockpit.py next   [--p P1]                   print open tasks (id<TAB>priority<TAB>text), highest priority first
  cockpit.py json                              dump state

State: ~/scratch/.cockpit/tasks.json (tasks + waiting), rebuilt view: ~/scratch/COCKPIT.md.
Claude in chat mirrors COCKPIT.md into the Cockpit doc; sessions write the ledger; this script joins them.
"""
import datetime as dt
import glob, json, os, subprocess, sys, uuid

HOME = os.path.expanduser("~")
DIR = f"{HOME}/scratch/.cockpit"
STATE = f"{DIR}/tasks.json"
OUT = f"{HOME}/scratch/COCKPIT.md"
LEDGER = f"{HOME}/.config/claude-launcher/ledger"
QLOG = f"{HOME}/scratch/.queue/done/queue.log"
PRIO = {"P1": 0, "P2": 1, "P3": 2}


def load():
    try:
        return json.load(open(STATE))
    except Exception:
        return {"tasks": [], "waiting": []}


def save(st):
    os.makedirs(DIR, exist_ok=True)
    json.dump(st, open(STATE, "w"), indent=1, ensure_ascii=False)


def now():
    return dt.datetime.now().strftime("%Y-%m-%d %H:%M")


def tmux_sessions():
    r = subprocess.run(["tmux", "ls", "-F", "#{session_name}\t#{session_created}"], capture_output=True, text=True)
    out = []
    for ln in r.stdout.splitlines():
        n, _, c = ln.partition("\t")
        try:
            out.append((n, dt.datetime.fromtimestamp(int(c)).strftime("%H:%M")))
        except Exception:
            out.append((n, ""))
    return out


def ledger_today():
    today = dt.date.today().isoformat()
    lines = []
    for f in sorted(glob.glob(f"{LEDGER}/*.md")):
        for ln in open(f, encoding="utf-8"):
            if ln.startswith("- " + today):
                lines.append(ln.strip())
    return lines


def queue_today():
    today = dt.date.today().isoformat()
    try:
        return [l.strip() for l in open(QLOG, encoding="utf-8") if l.startswith(today)]
    except FileNotFoundError:
        return []


def refresh(st):
    opn = sorted([t for t in st["tasks"] if t["status"] in ("todo", "running")],
                 key=lambda t: (PRIO.get(t["p"], 9), t["added"]))
    done = [t for t in st["tasks"] if t["status"] == "done" and t.get("done_at", "").startswith(dt.date.today().isoformat())]
    sess = tmux_sessions()
    L = [f"# COCKPIT — {now()}", "",
         "Source de vérité locale. `cc inbox` ajoute, `cc run` lance, les sessions écrivent le journal, `cockpit.py refresh` recompose. Claude (chat) reflète ce fichier dans le doc Cockpit.", "",
         "## Aujourd'hui, par priorité", "",
         "| id | P | Quoi | État | Projet / lien |", "| --- | --- | --- | --- | --- |"]
    for t in opn:
        link = t.get("link") or t.get("project") or ""
        L.append(f"| {t['id']} | {t['p']} | {t['text']} | {t['status']}{' (' + t.get('session','') + ')' if t.get('session') else ''} | {link} |")
    L += ["", "## En attente de toi", ""]
    for w in st["waiting"]:
        L.append(f"- [ ] ({w['id']}) {w['text']}")
    L += ["", "## En cours (sessions tmux)", ""]
    for n, c in sess:
        L.append(f"- {n} — depuis {c}")
    L += ["", "## Terminé aujourd'hui (journal des sessions)", ""] + (ledger_today() or ["- (rien encore)"])
    L += ["", "## Tâches closes aujourd'hui", ""] + ([f"- {t['text']} ({t.get('note','')})" for t in done] or ["- (rien encore)"])
    L += ["", "## File d'attente (queue runner)", ""] + ([f"- {q}" for q in queue_today()] or ["- (rien)"])
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w", encoding="utf-8").write("\n".join(L) + "\n")
    return OUT


def arg(a, k, default=None):
    return a[a.index(k) + 1] if k in a else default


def main():
    a = sys.argv[1:]
    if not a:
        sys.exit(__doc__)
    st = load()
    cmd = a[0]
    if cmd == "add":
        t = {"id": uuid.uuid4().hex[:6], "p": arg(a, "--p", "P2"), "text": arg(a, "--text", ""), "project": arg(a, "--project"),
             "link": arg(a, "--link"), "source": arg(a, "--source", "manual"), "status": "todo", "added": now()}
        if not t["text"]:
            sys.exit("--text required")
        st["tasks"].append(t); save(st); print(t["id"])
    elif cmd == "start":
        for t in st["tasks"]:
            if t["id"] == a[1]:
                t["status"] = "running"; t["session"] = arg(a, "--session", ""); t["started"] = now()
        save(st)
    elif cmd == "done":
        for t in st["tasks"]:
            if t["id"] == a[1]:
                t["status"] = "done"; t["done_at"] = now(); t["note"] = arg(a, "--note", "")
        save(st)
    elif cmd == "wait":
        w = {"id": uuid.uuid4().hex[:6], "text": arg(a, "--text", ""), "added": now()}
        st["waiting"].append(w); save(st); print(w["id"])
    elif cmd == "unwait":
        st["waiting"] = [w for w in st["waiting"] if w["id"] != a[1]]; save(st)
    elif cmd == "next":
        p = arg(a, "--p")
        for t in sorted([t for t in st["tasks"] if t["status"] == "todo" and (not p or t["p"] == p)],
                        key=lambda t: (PRIO.get(t["p"], 9), t["added"])):
            print(f"{t['id']}\t{t['p']}\t{t['text']}")
        return
    elif cmd == "json":
        print(json.dumps(st, indent=1, ensure_ascii=False)); return
    elif cmd != "refresh":
        sys.exit(__doc__)
    print(refresh(st))


if __name__ == "__main__":
    main()
KIT_EOF_4
mkdir -p "$T/launcher"
cat > "$T/launcher/com.cc-queue.plist" <<'KIT_EOF_5'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.cc-queue</string>
  <key>ProgramArguments</key>
  <array><string>/bin/zsh</string><string>-lc</string><string>$HOME/.config/claude-launcher/queue-runner.zsh</string></array>
  <key>StartInterval</key><integer>60</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardErrorPath</key><string>/tmp/cc-queue.err</string>
</dict>
</plist>
KIT_EOF_5
mkdir -p "$T/launcher"
cat > "$T/launcher/comms.py" <<'KIT_EOF_6'
#!/usr/bin/env python3
"""comms.py — the comms bank: messages to send, as Apple Reminders you can edit and copy from phone or Mac.

  comms.py sync        push ~/scratch/.cockpit/comms.json into the Reminders list "Comms" (new items only; existing kept)
  comms.py add --p P1 --to "Nom" --via whatsapp|email|slack --subject "..." --body "..." [--topic grievances]
  comms.py done <id>   mark sent (completes the reminder, keeps the record)
  comms.py suggest     who to contact this week, from open cockpit tasks × contacts.json
  comms.py list

Each reminder: title "P1 · WhatsApp · Nom — sujet", notes = the full draft (edit there, copy, paste, send).
Reminders priority: P1 = high, P2 = medium, P3 = low. The list is sorted by priority in Reminders (View > Sort by priority).
"""
import datetime as dt
import json, os, subprocess, sys, uuid

HOME = os.path.expanduser("~")
DIR = f"{HOME}/scratch/.cockpit"
COMMS = f"{DIR}/comms.json"
CONTACTS = f"{DIR}/contacts.json"
TASKS = f"{DIR}/tasks.json"
LIST = os.environ.get("CC_COMMS_LIST", "Comms")
PRIO_RM = {"P1": 1, "P2": 5, "P3": 9}
PRIO_ORD = {"P1": 0, "P2": 1, "P3": 2}


def osascript(script, *args):
    r = subprocess.run(["osascript", "-"] + list(args), input=script, text=True, capture_output=True)
    if r.returncode != 0:
        sys.exit(f"osascript failed: {r.stderr.strip()}")
    return r.stdout.rstrip("\n")


MAKE = '''
on run argv
  set L to item 1 of argv
  set t to item 2 of argv
  set b to item 3 of argv
  set p to (item 4 of argv) as integer
  tell application "Reminders"
    if not (exists list L) then make new list with properties {name:L}
    tell list L
      set r to make new reminder with properties {name:t, body:b, priority:p}
      return id of r
    end tell
  end tell
end run'''

COMPLETE = '''
on run argv
  tell application "Reminders"
    set r to reminder id (item 1 of argv)
    set completed of r to true
  end tell
end run'''


def load(p, default):
    try:
        return json.load(open(p, encoding="utf-8"))
    except Exception:
        return default


def save(p, d):
    os.makedirs(DIR, exist_ok=True)
    json.dump(d, open(p, "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def title(m):
    via = {"whatsapp": "WhatsApp", "email": "Mail", "slack": "Slack", "sms": "SMS"}.get(m.get("via", ""), m.get("via", ""))
    return f"{m['p']} · {via} · {m['to']} — {m['subject']}"


def sync():
    bank = load(COMMS, {"messages": []})
    n = 0
    for m in sorted(bank["messages"], key=lambda m: (PRIO_ORD.get(m["p"], 9), m.get("added", ""))):
        if m.get("reminder_id") or m.get("status") == "sent":
            continue
        rid = osascript(MAKE, LIST, title(m), m["body"], str(PRIO_RM.get(m["p"], 5)))
        m["reminder_id"] = rid; m["status"] = "in_reminders"; n += 1
    save(COMMS, bank)
    print(f"{n} reminder(s) added to '{LIST}'")


def add(a):
    def arg(k, d=None):
        return a[a.index(k) + 1] if k in a else d
    bank = load(COMMS, {"messages": []})
    m = {"id": uuid.uuid4().hex[:6], "p": arg("--p", "P2"), "to": arg("--to", "?"), "via": arg("--via", "whatsapp"),
         "subject": arg("--subject", ""), "body": arg("--body", ""), "topic": arg("--topic"), "status": "draft",
         "added": dt.datetime.now().strftime("%Y-%m-%d %H:%M")}
    bank["messages"].append(m); save(COMMS, bank); print(m["id"])


def done(mid):
    bank = load(COMMS, {"messages": []})
    for m in bank["messages"]:
        if m["id"] == mid:
            m["status"] = "sent"; m["sent_at"] = dt.datetime.now().strftime("%Y-%m-%d %H:%M")
            if m.get("reminder_id"):
                try:
                    osascript(COMPLETE, m["reminder_id"])
                except SystemExit:
                    pass
    save(COMMS, bank)


def suggest():
    contacts = load(CONTACTS, {"people": []})
    tasks = load(TASKS, {"tasks": []})
    open_tasks = [t for t in tasks["tasks"] if t["status"] in ("todo", "running")]
    bank = load(COMMS, {"messages": []})
    pending_to = {m["to"] for m in bank["messages"] if m["status"] != "sent"}
    out = []
    for p in contacts["people"]:
        hits = [t for t in open_tasks if (t.get("project") in p.get("projects", [])) or any(k.lower() in t["text"].lower() for k in p.get("keywords", []))]
        if hits:
            out.append((min(PRIO_ORD.get(t["p"], 9) for t in hits), p, hits))
    out.sort(key=lambda x: x[0])
    for _, p, hits in out:
        flag = " (brouillon en attente)" if p["name"] in pending_to else ""
        print(f"- {p['name']} — {p.get('role','')}{flag}: " + " ; ".join(t["text"][:70] for t in hits[:3]))
    return out


def main():
    a = sys.argv[1:]
    if not a:
        sys.exit(__doc__)
    if a[0] == "sync": sync()
    elif a[0] == "add": add(a)
    elif a[0] == "done": done(a[1])
    elif a[0] == "suggest": suggest()
    elif a[0] == "list":
        for m in sorted(load(COMMS, {"messages": []})["messages"], key=lambda m: (PRIO_ORD.get(m["p"], 9), m.get("added", ""))):
            print(f"{m['id']}  {m['status']:13} {title(m)}")
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
KIT_EOF_6
mkdir -p "$T/launcher"
cat > "$T/launcher/inbox.py" <<'KIT_EOF_7'
#!/usr/bin/env python3
"""cc inbox — route today's Apple Notes to-dos to terminal / Calendar / Reminders.

  inbox.py run [--yes] [--note TITLE]   classify today's note, show the plan, confirm, dispatch.
                                       Prints the lines classified as TASK on stdout (one per line),
                                       for the zsh wrapper to launch; everything else is handled here.
  inbox.py calendars                   list calendar names (to pick CC_CALENDAR)
  inbox.py lists                       list Reminders lists (to pick CC_REMINDERS_LIST)

Config (env or ~/.config/claude-launcher/config.json): CC_CALENDAR, CC_REMINDERS_LIST, CC_MODEL.
"""
import datetime as dt
import json, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import notes_ideas as notes  # noqa: E402


def cockpit_add(p, text, source):
    r = subprocess.run([sys.executable, os.path.join(HERE, "cockpit.py"), "add", "--p", p, "--text", text, "--source", source],
                       capture_output=True, text=True)
    return r.stdout.strip() or "------"


def _mark(titles, line, mk):
    return any(notes.mark(t.strip(), line, mk) for t in titles.split(" | ") if t.strip())

CONFIG_PATH = os.path.expanduser("~/.config/claude-launcher/config.json")
MARK = {"event": "📅", "reminder": "⏰", "task": "✅"}


def cfg(key, default=None):
    if os.environ.get(key):
        return os.environ[key]
    try:
        return json.load(open(CONFIG_PATH)).get(key, default)
    except Exception:
        return default


def save_cfg(key, value):
    try:
        data = json.load(open(CONFIG_PATH))
    except Exception:
        data = {}
    data[key] = value
    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    json.dump(data, open(CONFIG_PATH, "w"), indent=2, ensure_ascii=False)


# ---------- classification via claude -p ----------

PROMPT = """You are sorting a researcher's dictated to-do lines (French or English) into actions.
Today is {today} ({weekday}), timezone Europe/Paris. Working hours 9:00-19:00.

For each line, output one JSON object:
  "i":        line index (given)
  "type":     "task" | "event" | "reminder" | "skip"
  "title":    short clean title (keep the language of the line; for a call/meeting name the person)
  "start":    ISO datetime "YYYY-MM-DDTHH:MM" (events: required; reminders: due time, or null)
  "minutes":  event duration (default 30 for a call, 60 for a meeting)
  "notes":    anything else from the line worth keeping (or "")
  "p":        "P1" | "P2" | "P3"  (P1 = blocks someone else or a deadline this week; P2 = this week; P3 = later)

Rules:
- event = something at a time with other people or a fixed slot (call, meeting, réunion, RDV, demo, visio, déjeuner).
- reminder = a thing to do by a time with no work session behind it (send, reply, pay, book, relancer, répondre, envoyer).
- task = a piece of work to open a working session on (analyse, write, build, draft, rédiger, coder, tester, explorer…).
- skip = not actionable (a thought, a quote, a link with no verb).
- "tomorrow/demain", weekday names, "next week/la semaine prochaine" are relative to today. "Thursday" on a Thursday means next Thursday.
- If an event has no time, use 10:00. If a reminder has no time, use 09:00 of the day mentioned, or null if no day.
Output ONLY a JSON array, no prose, no code fences.

Lines:
{lines}
"""


def classify(lines):
    today = dt.date.today()
    numbered = "\n".join(f'{i}. {l}' for i, l in enumerate(lines))
    prompt = PROMPT.format(today=today.isoformat(), weekday=today.strftime("%A"), lines=numbered)
    cmd = ["claude", "-p", prompt]
    model = cfg("CC_MODEL")
    if model:
        cmd += ["--model", model]
    r = subprocess.run(cmd, text=True, capture_output=True)
    if r.returncode != 0:
        sys.exit(f"claude -p failed: {r.stderr.strip()[:300]}")
    txt = r.stdout.strip()
    m = re.search(r"\[.*\]", txt, re.S)
    if not m:
        sys.exit(f"could not parse classification:\n{txt[:500]}")
    items = json.loads(m.group(0))
    by_i = {it.get("i"): it for it in items if isinstance(it, dict)}
    out = []
    for i, l in enumerate(lines):
        it = by_i.get(i, {"type": "skip"})
        it.setdefault("title", l); it.setdefault("start", None); it.setdefault("minutes", 30); it.setdefault("notes", ""); it.setdefault("p", "P2")
        it["line"] = l; it["i"] = i
        out.append(it)
    return out


# ---------- Calendar / Reminders via AppleScript ----------

def _as_date_expr(iso):
    d = dt.datetime.fromisoformat(iso)
    return f'my mkdate({d.year}, {d.month}, {d.day}, {d.hour}, {d.minute})'


MKDATE = '''
on mkdate(y, mo, d, h, mi)
  set t to current date
  set day of t to 1
  set year of t to y
  set month of t to mo
  set day of t to d
  set hours of t to h
  set minutes of t to mi
  set seconds of t to 0
  return t
end mkdate
'''


def list_calendars():
    return notes.osascript('tell application "Calendar" to return name of every calendar').split(", ")


def list_reminder_lists():
    return notes.osascript('tell application "Reminders" to return name of every list').split(", ")


def pick(prompt, options):
    for i, o in enumerate(options, 1):
        print(f"  {i}. {o}", file=sys.stderr)
    while True:
        s = input(prompt).strip()
        if s.isdigit() and 1 <= int(s) <= len(options):
            return options[int(s) - 1]


def add_event(cal, title, start_iso, minutes, body):
    end = (dt.datetime.fromisoformat(start_iso) + dt.timedelta(minutes=int(minutes or 30))).isoformat(timespec="minutes")
    script = MKDATE + f'''
on run argv
  set cal to item 1 of argv
  set t to item 2 of argv
  set b to item 3 of argv
  set s to {_as_date_expr(start_iso)}
  set e to {_as_date_expr(end)}
  tell application "Calendar"
    tell calendar cal
      make new event with properties {{summary:t, start date:s, end date:e, description:b}}
    end tell
  end tell
end run'''
    notes.osascript(script, cal, title, body or "")


def add_reminder(lst, title, due_iso, body):
    due = f"set due date of r to {_as_date_expr(due_iso)}" if due_iso else ""
    script = MKDATE + f'''
on run argv
  set l to item 1 of argv
  set t to item 2 of argv
  set b to item 3 of argv
  tell application "Reminders"
    tell list l
      set r to make new reminder with properties {{name:t, body:b}}
      {due}
    end tell
  end tell
end run'''
    notes.osascript(script, lst, title, body or "")


# ---------- main flow ----------

def fmt_when(it):
    if not it.get("start"):
        return "—"
    d = dt.datetime.fromisoformat(it["start"])
    return d.strftime("%a %d %b %H:%M")


def run(auto_yes=False, title=None):
    titles = [title] if title else notes.find_today_notes()
    if not titles:
        sys.exit("no note for today")
    title = " | ".join(titles)
    lines = []
    for t in titles:
        lines += notes.open_lines(t, today_only=True)
    lines = list(dict.fromkeys(lines))
    if not lines:
        print(f"nothing open in '{title}'", file=sys.stderr); return
    print(f"note: {title} — {len(lines)} open line(s), classifying…", file=sys.stderr)
    items = classify(lines)

    print("", file=sys.stderr)
    for it in items:
        tag = {"task": "TASK    ", "event": "EVENT   ", "reminder": "REMINDER", "skip": "skip    "}[it["type"]]
        extra = f"  {fmt_when(it)}" if it["type"] in ("event", "reminder") else f"  {it.get('p','')}"
        print(f"  [{it['i']}] {tag}{extra}  {it['title']}", file=sys.stderr)
    print("", file=sys.stderr)

    if not auto_yes:
        ans = input("Dispatch? [Enter = yes / n = no / numbers to skip, e.g. '2 4' / 'e3' make 3 an event, 'r3' reminder, 't3' task]: ").strip()
        if ans.lower() in ("n", "no", "q"):
            print("cancelled", file=sys.stderr); return
        for tok in ans.split():
            if tok.isdigit():
                items[int(tok)]["type"] = "skip"
            elif tok[0] in "ert" and tok[1:].isdigit():
                items[int(tok[1:])]["type"] = {"e": "event", "r": "reminder", "t": "task"}[tok[0]]

    cal = cfg("CC_CALENDAR"); lst = cfg("CC_REMINDERS_LIST")
    if any(it["type"] == "event" for it in items) and not cal:
        cal = pick("Which calendar for events? ", list_calendars()); save_cfg("CC_CALENDAR", cal)
    if any(it["type"] == "reminder" for it in items) and not lst:
        lst = pick("Which Reminders list? ", list_reminder_lists()); save_cfg("CC_REMINDERS_LIST", lst)

    # Bare lines (links, sub-points) right after a task belong to it: attach them as context, tick them with it.
    for k, it in enumerate(items):
        if it["type"] != "task":
            continue
        extra = []
        for nxt in items[k + 1:]:
            if nxt["type"] == "skip" and not nxt.get("attached"):
                extra.append(nxt["line"]); nxt["attached"] = True; nxt["parent"] = k
            else:
                break
        if extra:
            it["context"] = extra
            print(f"  (task [{k}] takes {len(extra)} following line(s) as context)", file=sys.stderr)

    tasks = []
    for it in items:
        t = it["type"]
        try:
            if t == "event":
                if not it.get("start"):
                    print(f"  ! no time for event '{it['title']}', making it a reminder instead", file=sys.stderr)
                    add_reminder(lst or (cfg("CC_REMINDERS_LIST")), it["title"], None, it["line"])
                else:
                    add_event(cal, it["title"], it["start"], it.get("minutes", 30), it["line"])
                _mark(title, it["line"], MARK["event"])
                print(f"  📅 {it['title']} — {fmt_when(it)}", file=sys.stderr)
            elif t == "reminder":
                add_reminder(lst, it["title"], it.get("start"), it["line"])
                _mark(title, it["line"], MARK["reminder"])
                print(f"  ⏰ {it['title']} — {fmt_when(it)}", file=sys.stderr)
            elif t == "task":
                text = it["line"]
                if it.get("context"):
                    text += " — " + " | ".join(it["context"])
                    for c in it["context"]:
                        try:
                            _mark(title, c, MARK["task"])
                        except SystemExit:
                            pass
                # record in the cockpit; the zsh wrapper launches (or queues) and marks the line ✅
                tid = cockpit_add(it.get("p", "P2"), it["line"], "inbox")
                tasks.append(f"{tid}\t{it.get('p','P2')}\t{text}")
        except SystemExit as e:
            print(f"  ! failed on '{it['title']}': {e}", file=sys.stderr)
    # stdout: tasks only (machine-readable for cc): id<TAB>priority<TAB>text
    print("\n".join(tasks))
    subprocess.run([sys.executable, os.path.join(HERE, "cockpit.py"), "refresh"], capture_output=True)


def main():
    a = sys.argv[1:]
    if not a:
        sys.exit(__doc__)
    if a[0] == "calendars":
        print("\n".join(list_calendars()))
    elif a[0] == "lists":
        print("\n".join(list_reminder_lists()))
    elif a[0] == "run":
        auto = "--yes" in a
        title = None
        if "--note" in a:
            title = a[a.index("--note") + 1]
        run(auto, title)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
KIT_EOF_7
mkdir -p "$T/launcher"
cat > "$T/launcher/install-services.sh" <<'KIT_EOF_8'
#!/bin/zsh
# Registers the two Quick Actions (Accentuer, Launch idea) copied to ~/Library/Services, and makes scripts executable.
set -e
chmod +x ~/.config/claude-launcher/*.sh ~/.config/claude-launcher/*.py
/System/Library/CoreServices/pbs -update 2>/dev/null || true
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
echo "Quick Actions registered. Test: select text anywhere → right-click → Services → Accentuer."
echo "Keyboard shortcut (optional): System Settings → Keyboard → Keyboard Shortcuts… → Services → Text → Accentuer."
# keyboard shortcut ⌃⌥A for Accentuer (Services menu)
defaults write pbs NSServicesStatus -dict-add '"(null) - Accentuer - runWorkflowAsService"' '{ key_equivalent = "^~a"; enabled_context_menu = 1; enabled_services_menu = 1; presented_at_least_once = 1; }'
/System/Library/CoreServices/pbs -update 2>/dev/null || true
echo "Hotkey: Ctrl+Option+A runs Accentuer on the selected text (if it doesn't take, log out/in once)."
# queue runner: the Mac picks up tasks dropped in ~/scratch/.queue every minute (from the phone, via Claude)
mkdir -p "$HOME/scratch/.queue/done"
sed "s|\$HOME|$HOME|g" "$HOME/.config/claude-launcher/com.cc-queue.plist" > "$HOME/Library/LaunchAgents/com.cc-queue.plist"
launchctl unload "$HOME/Library/LaunchAgents/com.cc-queue.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.cc-queue.plist" && echo "Queue runner loaded (every 60 s)."
KIT_EOF_8
mkdir -p "$T/launcher"
cat > "$T/launcher/launch-idea.sh" <<'KIT_EOF_9'
#!/bin/zsh
# Called by the "Launch idea" Shortcut / Quick Action with the selected text as $1 (or on stdin).
# Opens a Terminal window and runs `cc idea "<text>"` there.
text="${1:-$(cat)}"
text="${text//$'\n'/ }"
[[ -z "$text" ]] && exit 1
q=$(printf '%q' "$text")
osascript - "$q" <<'APPLESCRIPT'
on run argv
  tell application "Terminal"
    activate
    do script "cc idea " & item 1 of argv
  end tell
end run
APPLESCRIPT
KIT_EOF_9
mkdir -p "$T/launcher"
cat > "$T/launcher/memo.py" <<'KIT_EOF_10'
#!/usr/bin/env python3
"""cc memo — draft the weekly group memo from what happened in your terminal sessions.

  memo.py [--since YYYY-MM-DD] [--days N] [--previous PATH] [--no-open]
  memo.py --message [PATH]     WhatsApp message from the memo (latest draft, or PATH): asks first, named
                               owners, deadlines, one link per ask. Copied to the clipboard; also prints
                               "relances" lines to paste into today's note for cc inbox.

Sources (your own work only):
  - the ledger:   ~/.config/claude-launcher/ledger/*.md   (one line per finished task, written by Claude Code sessions)
  - project logs: <project>/notes/log.md for every registered project that has one
  - git:          git log --since … for every registered project that is a repo
Output: ~/scratch/.memo/memo-<date>.md — your rows pre-filled, placeholders for the others. Opened in your editor.
"""
import datetime as dt
import glob, os, subprocess, sys

HOME = os.path.expanduser("~")
REG = os.environ.get("CC_REGISTRY", f"{HOME}/.config/claude-launcher/projects.txt")
LEDGER = f"{HOME}/.config/claude-launcher/ledger"
OUT = f"{HOME}/scratch/.memo"
MODEL = os.environ.get("CC_MODEL")

TEMPLATE = """# Mémo au groupe : ce qui a avancé depuis {prev_day}

*{today_long}*

Bonjour à tous,

Voici ce qui a avancé depuis [le point de {prev_day}](LIEN-MEMO-PRECEDENT), avec les liens vers chaque document et ce que chacun peut en faire d'ici la fin de la semaine. En bref : <une phrase>.

## À faire avant <jour>

- [ ] …

## Qui travaille sur quoi

* **<Chantier> : <personnes>.** <état en 3-6 mots>.

| Chantier | Ce qui a avancé | Ce que vous pouvez faire | Liens |
| :---- | :---- | :---- | :---- |
| **<Chantier>** | <une ou deux phrases, factuelles> | <action + date> | [titre](lien) |

## Prochaines échéances

- **<Jour date>** : …

Merci à tous pour ce travail. N'hésitez pas à commenter directement dans les documents.

l'utilisateur
"""

PROMPT = """Tu rédiges le brouillon du point hebdomadaire de l'utilisateur à son équipe, en français, dans EXACTEMENT le format du modèle ci-dessous (mêmes titres, même tableau, mêmes conventions typographiques : guillemets « », « Md€ », liens markdown).

Tu disposes uniquement de ce qu'l'utilisateur a fait lui-même cette semaine (journal de ses sessions de travail, logs de projets, commits git). Donc :
- Remplis complètement les lignes et les rangées du tableau qui concernent le travail de l'utilisateur, en te basant sur les faits du journal (pas d'invention ; si un lien est présent dans le journal, reprends-le).
- Pour les chantiers des autres membres, mets une rangée avec « <à dicter> » dans « Ce qui a avancé ».
- Garde les noms de chantiers du mémo précédent quand il est fourni, et son « Qui travaille sur quoi » comme base, mis à jour avec ce que le journal montre.
- Style : phrases courtes, factuelles, verbes d'action. Pas d'adjectifs creux.
- Le paragraphe « En bref » résume en une phrase ce qui a avancé côté l'utilisateur, en laissant <…> pour le reste.
Réponds uniquement avec le mémo en markdown, sans commentaire.

=== MODÈLE ===
{template}

=== MÉMO PRÉCÉDENT (peut être vide) ===
{previous}

=== JOURNAL DE TRAVAIL DEPUIS LE {since} ===
{journal}
"""

FR_DAYS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
FR_MONTHS = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
             "septembre", "octobre", "novembre", "décembre"]


def fr_long(d):
    day = "1er" if d.day == 1 else str(d.day)
    return f"{day} {FR_MONTHS[d.month - 1]} {d.year}"


def projects():
    out = []
    try:
        for ln in open(REG, encoding="utf-8"):
            ln = ln.rstrip("\n")
            if not ln or ln.lstrip().startswith("#") or "\t" not in ln:
                continue
            n, p = ln.split("\t", 1)
            out.append((n, p.replace("~", HOME, 1) if p.startswith("~") else p))
    except FileNotFoundError:
        pass
    return out


def read_ledger(since):
    chunks = []
    for f in sorted(glob.glob(f"{LEDGER}/*.md")):
        for ln in open(f, encoding="utf-8"):
            s = ln.strip()
            if s.startswith("- ") and s[2:12] >= since.isoformat():
                chunks.append(s)
    return "\n".join(chunks)


def read_logs(since):
    chunks = []
    for n, p in projects():
        f = os.path.join(p, "notes", "log.md")
        if os.path.isfile(f):
            keep = [l.rstrip() for l in open(f, encoding="utf-8") if l.strip() and l.strip()[2:12] >= since.isoformat()]
            if keep:
                chunks.append(f"### {n}\n" + "\n".join(keep))
    return "\n\n".join(chunks)


def read_git(since):
    chunks = []
    for n, p in projects():
        if not os.path.isdir(os.path.join(p, ".git")):
            continue
        r = subprocess.run(["git", "-C", p, "log", f"--since={since.isoformat()}", "--pretty=format:%ad %s", "--date=short"],
                           text=True, capture_output=True)
        if r.returncode == 0 and r.stdout.strip():
            chunks.append(f"### git {n}\n{r.stdout.strip()}")
    return "\n\n".join(chunks)


MSG_PROMPT = """Tu transformes le mémo hebdomadaire d'l'utilisateur (ci-dessous) en message WhatsApp pour le groupe, en français.
Objectif : que chacun sache en 20 secondes ce qu'on attend de lui, de qui, pour quand.

Structure obligatoire :
1. « Hello tout le monde ! » puis, s'il y a une nouvelle (arrivée, décision), une phrase.
2. « 🔴 3 choses à faire cette semaine » : au plus 3 lignes numérotées 1️⃣ 2️⃣ 3️⃣. Chacune = @Prénom Nom (ou « Tout le monde ») : action concrète → échéance → un seul lien. Prends les actions du mémo (« Ce que vous pouvez faire », « À faire »). Si l'échéance manque dans le mémo, écris [échéance] entre crochets pour qu'l'utilisateur la fixe.
3. Si le mémo contient une demande nouvelle (ex. messages pour la plume), un bloc « 🎥 Nouveau : … » de 3 lignes max avec le format attendu et une échéance.
4. « 📅 La semaine » : les 3 à 5 rendez-vous du planning, une ligne chacun, format « Jeu. 5 : … ».
5. « 📄 Le mémo complet : LIEN-MEMO » puis « Merci à tous ! l'utilisateur ».
Contraintes : 220 mots max hors liens ; pas de markdown (WhatsApp) ; conserve les @mentions telles quelles ; ne rien inventer, les crochets [ ] signalent ce qu'l'utilisateur doit compléter.

Puis, après une ligne « --- RELANCES ---», liste 2 à 5 lignes à coller dans la note du jour d'l'utilisateur, une par demande, au format « relancer <Prénom> sur <objet> <jour> » avec le jour = le lendemain de l'échéance.

=== MÉMO ===
{memo}
"""


def message(a):
    path = None
    i = a.index("--message")
    if i + 1 < len(a) and not a[i + 1].startswith("--"):
        path = a[i + 1]
    if not path:
        prev = sorted(glob.glob(f"{OUT}/memo-*.md"))
        if not prev:
            sys.exit("no memo draft found; run `cc memo` first or pass a path")
        path = prev[-1]
    memo = open(path, encoding="utf-8").read()
    cmd = ["claude", "-p", MSG_PROMPT.format(memo=memo)] + (["--model", MODEL] if MODEL else [])
    r = subprocess.run(cmd, text=True, capture_output=True)
    if r.returncode != 0:
        sys.exit(f"claude -p failed: {r.stderr.strip()[:300]}")
    out = r.stdout.strip()
    msg, _, relances = out.partition("--- RELANCES ---")
    today = dt.date.today().isoformat()
    os.makedirs(OUT, exist_ok=True)
    mp = f"{OUT}/message-{today}.txt"
    open(mp, "w", encoding="utf-8").write(msg.strip() + "\n")
    subprocess.run(["pbcopy"], input=msg.strip(), text=True)
    print(msg.strip())
    print(f"\n[copied to clipboard; saved to {mp}]", file=sys.stderr)
    if relances.strip():
        print("\nÀ coller dans la note du jour (puis cc inbox) :", file=sys.stderr)
        print(relances.strip(), file=sys.stderr)


def main():
    a = sys.argv[1:]
    if "--message" in a:
        return message(a)
    today = dt.date.today()
    days = int(a[a.index("--days") + 1]) if "--days" in a else 7
    since = dt.date.fromisoformat(a[a.index("--since") + 1]) if "--since" in a else today - dt.timedelta(days=days)
    previous = ""
    if "--previous" in a:
        previous = open(a[a.index("--previous") + 1], encoding="utf-8").read()
    else:
        prev = sorted(glob.glob(f"{OUT}/memo-*.md"))
        if prev:
            previous = open(prev[-1], encoding="utf-8").read()

    journal = "\n\n".join(x for x in (
        "## Ledger\n" + (read_ledger(since) or "(vide)"),
        "## Logs de projets\n" + (read_logs(since) or "(vide)"),
        "## Git\n" + (read_git(since) or "(vide)"),
    ))
    template = TEMPLATE.format(prev_day=FR_DAYS[since.weekday()], today_long=fr_long(today))
    prompt = PROMPT.format(template=template, previous=previous or "(aucun)", since=fr_long(since), journal=journal)

    print(f"journal since {since} — {len(journal)} chars; drafting…", file=sys.stderr)
    cmd = ["claude", "-p", prompt] + (["--model", MODEL] if MODEL else [])
    r = subprocess.run(cmd, text=True, capture_output=True)
    if r.returncode != 0:
        sys.exit(f"claude -p failed: {r.stderr.strip()[:300]}")
    os.makedirs(OUT, exist_ok=True)
    path = f"{OUT}/memo-{today.isoformat()}.md"
    open(path, "w", encoding="utf-8").write(r.stdout.strip() + "\n")
    # keep the raw journal next to it, useful when dictating the rest
    open(f"{OUT}/journal-{today.isoformat()}.md", "w", encoding="utf-8").write(journal)
    print(path)
    if "--no-open" not in a:
        subprocess.run(["open", path])


if __name__ == "__main__":
    main()
KIT_EOF_10
mkdir -p "$T/launcher"
cat > "$T/launcher/notes_ideas.py" <<'KIT_EOF_11'
#!/usr/bin/env python3
"""Bridge between Apple Notes and the cc launcher.

  notes_ideas.py list   [--note TITLE]          -> prints open to-do lines, one per line
  notes_ideas.py mark   [--note TITLE] LINE     -> prefixes LINE with a check mark in the note
  notes_ideas.py notes                          -> prints all note titles (to find the right one)
  notes_ideas.py today-note                     -> title of today's note (date in title > created today > modified today)
  notes_ideas.py today                          -> title of today's note, then its open to-do lines
  notes_ideas.py slug   TEXT                    -> prints a folder-safe slug for TEXT

Default note title: $CC_NOTE or "Ideas". Only the note is read/written; nothing else in Notes is touched.
"""
import html, os, re, subprocess, sys, unicodedata

DONE_MARKS = ("✅", "✓", "☑", "📅", "⏰", "[x]", "[X]", "- [x]")


def osascript(script, *args):
    r = subprocess.run(["osascript", "-"] + list(args), input=script, text=True, capture_output=True)
    if r.returncode != 0:
        sys.exit(f"osascript failed: {r.stderr.strip()}")
    return r.stdout.rstrip("\n")


def note_title():
    return os.environ.get("CC_NOTE", "Ideas")


GET_PLAIN = '''
on run argv
  tell application "Notes"
    set t to item 1 of argv
    set ns to (every note whose name is t)
    if (count of ns) = 0 then error "no note titled " & t
    return plaintext of item 1 of ns
  end tell
end run'''

GET_BODY = GET_PLAIN.replace("return plaintext", "return body")

GET_PLAIN_ALL = '''
on run argv
  tell application "Notes"
    set t to item 1 of argv
    set ns to (every note whose name is t)
    if (count of ns) = 0 then error "no note titled " & t
    set out to {}
    repeat with n in ns
      set end of out to (plaintext of n)
    end repeat
  end tell
  set AppleScript's text item delimiters to (ASCII character 30)
  return out as text
end run'''

GET_BODIES = GET_PLAIN_ALL.replace("plaintext of n", "body of n")

SET_BODY_NTH = '''
on run argv
  tell application "Notes"
    set t to item 1 of argv
    set ns to (every note whose name is t)
    set body of item ((item 2 of argv) as integer) of ns to item 3 of argv
  end tell
end run'''

SET_BODY = '''
on run argv
  tell application "Notes"
    set t to item 1 of argv
    set ns to (every note whose name is t)
    if (count of ns) = 0 then error "no note titled " & t
    set body of item 1 of ns to item 2 of argv
  end tell
end run'''

LIST_NOTES = '''
tell application "Notes" to set ns to name of every note
set AppleScript's text item delimiters to (ASCII character 30)
return ns as text'''

# names of notes created / modified since local midnight, one per line, most recent first
NOTES_SINCE_MIDNIGHT = '''
on run argv
  set d to current date
  set time of d to 0
  set out to {}
  tell application "Notes"
    if item 1 of argv is "created" then
      set ns to (every note whose creation date ≥ d)
    else
      set ns to (every note whose modification date ≥ d)
    end if
    repeat with n in ns
      set end of out to (name of n)
    end repeat
  end tell
  set AppleScript's text item delimiters to linefeed
  return out as text
end run'''


def find_today_notes(date=None):
    """Titles of today's to-do notes: all with the date in the title; else created today; else modified today."""
    import datetime as _dt
    d = date or _dt.date.today()
    pats = _today_patterns(d)
    names = [n for n in osascript(LIST_NOTES).split(chr(30)) if n]
    # titles: explicit dates only (no "today"/weekday words — too many false positives in titles)
    tpats = _today_patterns(d, words=False)
    dated = [n for n in names if any(p.search(n) for p in tpats)]
    if dated:
        return list(dict.fromkeys(dated))
    for mode in ("created", "modified"):
        cands = [n for n in osascript(NOTES_SINCE_MIDNIGHT, mode).split("\n") if n.strip()]
        if cands:
            return list(dict.fromkeys(cands))
    return []


def find_today_note(date=None):
    ts = find_today_notes(date)
    return ts[0] if ts else None


FR_MONTHS = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
             "septembre", "octobre", "novembre", "décembre"]
FR_DAYS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
EN_DAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

# a short line containing something date-like is treated as a section heading
ANY_DATE = re.compile(
    r"\b\d{4}-\d{2}-\d{2}\b"
    r"|\b\d{1,2}[/.]\d{1,2}([/.]\d{2,4})?\b"
    r"|\b\d{1,2}(st|nd|rd|th|er)?\s+[a-zéû]{3,9}\b"      # 4 nov, 4 novembre, 1er déc
    r"|\b[a-z]{3,9}\.?\s+\d{1,2}(st|nd|rd|th)?\b"         # nov 4, november 4th
    r"|\b(today|aujourd.hui|" + "|".join(FR_DAYS + EN_DAYS) + r")\b",
    re.I,
)


def _today_patterns(d, words=True):
    """Regexes matching a heading that refers to date d. words=False: explicit dates only."""
    day, mon, yr = d.day, d.month, d.year
    en3, fr3 = d.strftime("%b").lower(), FR_MONTHS[mon - 1][:3]
    pats = [
        rf"\b{yr}-{mon:02d}-{day:02d}\b",
        rf"\b0?{day}[/.]0?{mon}([/.]({yr}|{yr % 100}))?\b",
        rf"\b{day}(st|nd|rd|th|er)?\s+{en3}[a-z]*\b", rf"\b{en3}[a-z]*\.?\s+{day}(st|nd|rd|th)?\b",
        rf"\b{day}(er)?\s+{fr3}[a-zéû]*\b",
    ]
    if words:
        pats.append(rf"\b(today|aujourd.hui|{FR_DAYS[d.weekday()]}|{EN_DAYS[d.weekday()]})\b")
    return [re.compile(p, re.I) for p in pats]


def _is_date_heading(s):
    return len(s) <= 40 and bool(ANY_DATE.search(s))


def open_lines(title, today_only=False, date=None):
    """Open to-do lines across ALL notes with this title (same-title notes are merged)."""
    import datetime as _dt
    plains = osascript(GET_PLAIN_ALL, title).split(chr(30))
    lines = []
    for pl in plains:
        lines += pl.split("\n")[1:]  # first line of each note is its title
    d = date or _dt.date.today()
    pats = _today_patterns(d)
    saw_heading, in_today = False, False
    today, all_open = [], []
    for ln in lines:
        s = ln.strip().lstrip("-•*·# ").strip()
        if not s:
            continue
        if _is_date_heading(s):
            saw_heading = True
            in_today = any(p.search(s) for p in pats)
            continue
        if s.startswith(DONE_MARKS):
            continue
        all_open.append(s)
        if in_today:
            today.append(s)
    if today_only and saw_heading:
        return today
    return all_open  # no date headings → the whole note counts as today


def mark(title, line, mark="✅"):
    """Prefix the matching line with `mark` in whichever same-titled note holds it."""
    bodies = osascript(GET_BODIES, title).split(chr(30))
    target = line.strip()
    for k, body in enumerate(bodies, 1):
        parts = re.split(r"(<[^>]+>)", body)  # alternating text / tag
        for i, seg in enumerate(parts):
            if seg.startswith("<") or not seg.strip():
                continue
            plain = html.unescape(seg)
            core = plain.strip().lstrip("-•*· ").strip()
            if core == target or (target and target in core):
                lead = plain[: len(plain) - len(plain.lstrip())]
                parts[i] = html.escape(lead + mark + " " + plain.lstrip(), quote=False)
                osascript(SET_BODY_NTH, title, str(k), "".join(parts))
                return True
    return False


def slug(text, max_words=5):
    t = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    words = re.findall(r"[A-Za-z0-9]+", t.lower())
    s = "-".join(words[:max_words]) or "idea"
    return s[:40].rstrip("-")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    cmd, rest = sys.argv[1], sys.argv[2:]
    title = note_title()
    if rest[:1] == ["--note"]:
        title, rest = rest[1], rest[2:]
    if cmd == "list":
        print("\n".join(open_lines(title)))
    elif cmd == "today-note":
        ts = find_today_notes()
        if not ts:
            sys.exit("no note for today (title with today's date, or created/modified today)")
        print(" | ".join(ts))
    elif cmd == "today":
        # first output line: today's note title(s) joined by " | "; then the open lines of all of them
        ts = find_today_notes()
        if not ts:
            sys.exit("no note for today (title with today's date, or created/modified today)")
        print(" | ".join(ts))
        out = []
        for t in ts:
            out += open_lines(t, today_only=True)
        print("\n".join(dict.fromkeys(out)))
    elif cmd == "mark":
        mk = "✅"
        if rest[:1] == ["--mark"]:
            mk, rest = rest[1], rest[2:]
        ok = any(mark(t.strip(), " ".join(rest), mk) for t in title.split(" | ") if t.strip())
        print("marked" if ok else "line not found in note (left unchanged)", file=sys.stderr)
        sys.exit(0 if ok else 2)
    elif cmd == "notes":
        print(osascript(LIST_NOTES).replace(chr(30), "\n"))
    elif cmd == "slug":
        print(slug(" ".join(rest)))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
KIT_EOF_11
mkdir -p "$T/launcher"
cat > "$T/launcher/projects.txt" <<'KIT_EOF_12'
# Registre des projets — une ligne par projet : <nom><TAB><chemin>
# `cc add` enregistre le dossier courant ; `cc new <nom>` crée un projet dans ~/scratch.
scratch	~/scratch
KIT_EOF_12
mkdir -p "$T/launcher"
cat > "$T/launcher/queue-runner.zsh" <<'KIT_EOF_13'
#!/bin/zsh
# Processes ~/scratch/.queue every minute (launchd). Lets Claude (from the phone, via the desktop app's file bridge)
# or anything else drop work for the Mac to run:
#   ~/scratch/.queue/<name>.task   → text = a task line: new scratch project + Claude session started in tmux (detached)
#   ~/scratch/.queue/<name>.cmd    → text = a cc command, e.g. "riposte" or "memo --message"; run inside tmux
#   ~/scratch/.queue/INBOX         → runs `cc inbox --yes` (no confirmation) once, then deletes the flag
# Each file is moved to ~/scratch/.queue/done/ with a .log next to it.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
source "$HOME/.config/claude-launcher/cc.zsh"
Q="$HOME/scratch/.queue"; mkdir -p "$Q/done"
log() { print -r -- "$(date '+%F %T') $*" >> "$Q/done/queue.log" }
setopt null_glob
for f in "$Q"/*.task; do
  text=$(<"$f"); text="${text//$'\n'/ }"
  [[ -z "$text" ]] && { mv "$f" "$Q/done/"; continue; }
  n=$(python3 "$CC_NOTES_PY" slug "$text"); [[ -e "$CC_SCRATCH/$n" ]] && n="$n-$(date +%m%d-%H%M)"
  _cc_create "$n" "$text" >/dev/null || { log "FAILED create $f"; mv "$f" "$Q/done/"; continue; }
  tid="${$(basename "$f")%.task}"; [[ "$tid" == [0-9a-f](#c6) ]] && print -r -- "- cockpit id: $tid" >> "$CC_SCRATCH/$n/notes/log.md"
  sess=$(_cc_session_name "$CC_SCRATCH/$n")
  prompt="New task from my notes: ${text}. Read CLAUDE.md, rewrite the 'What this is' section in your own words, then do the work end to end without waiting for me; write results to output/, log one line in notes/log.md and one in the ledger."
  tmux new-session -d -s "$sess" -c "$CC_SCRATCH/$n" 2>/dev/null
  tmux send-keys -t "=$sess" "claude ${(q)prompt}" Enter
  tid="${$(basename "$f")%.task}"
  [[ "$tid" == [0-9a-f](#c6) ]] && python3 "$HOME/.config/claude-launcher/cockpit.py" start "$tid" --session "$sess" >/dev/null 2>&1
  log "started session $sess from $(basename $f)"; mv "$f" "$Q/done/"
done
for f in "$Q"/*.cmd; do
  cmd=$(<"$f"); cmd="${cmd//$'\n'/ }"
  sess="queue-$(date +%H%M%S)"
  tmux new-session -d -s "$sess" -c "$HOME" 2>/dev/null
  tmux send-keys -t "=$sess" "source ~/.config/claude-launcher/cc.zsh; cc $cmd" Enter
  log "ran: cc $cmd (session $sess)"; mv "$f" "$Q/done/"
done
if [[ -f "$Q/INBOX" ]]; then
  rm -f "$Q/INBOX"
  out=$(python3 "$CC_INBOX_PY" run --yes 2>>"$Q/done/queue.log")
  for t in "${(@f)out}"; do [[ -n "$t" ]] && print -r -- "$t" > "$Q/$(date +%s)-$RANDOM.task"; done
  log "inbox processed"
fi
python3 "$HOME/.config/claude-launcher/cockpit.py" refresh >/dev/null 2>&1
KIT_EOF_13
mkdir -p "$T/launcher"
cat > "$T/launcher/tmux.conf" <<'KIT_EOF_14'
# minimal tmux config for running several Claude Code sessions
set -g mouse on                       # click panes, scroll with trackpad
set -g history-limit 50000
set -g default-terminal "screen-256color"
set -g base-index 1
set -g renumber-windows on
set -g status-left-length 30
set -g status-left "#[bold]#S  "      # session (= project) name on the left
set -g status-right "%H:%M"
set -g escape-time 0
# Prefix (Ctrl-b) then:  s = switch session   d = detach   [ = scroll mode   q = quit scroll
# Prefix then ( / ) = previous / next session
bind -n M-Left  switch-client -p      # Option+← / Option+→ cycles projects without the prefix
bind -n M-Right switch-client -n
KIT_EOF_14
mkdir -p "$T/launcher"
cat > "$T/launcher/vscode_settings_snippet.json" <<'KIT_EOF_15'
{
  "// paste these keys into VS Code User settings.json (Cmd+Shift+P → 'Preferences: Open User Settings (JSON)')": "",
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/**": true,
    "**/.venv/**": true,
    "**/__pycache__/**": true,
    "**/data/**": true,
    "**/raw/**": true,
    "**/derived/**": true,
    "**/output/**": true,
    "**/outputs/**": true,
    "**/out/**": true,
    "**/_backup/**": true,
    "**/agent_backups/**": true,
    "**/*.csv": true,
    "**/*.parquet": true,
    "**/*.dta": true,
    "**/*.zip": true,
    "**/*.pdf": true
  },
  "search.exclude": {
    "**/data/**": true,
    "**/raw/**": true,
    "**/derived/**": true,
    "**/output/**": true,
    "**/outputs/**": true,
    "**/.venv/**": true,
    "**/_backup/**": true,
    "**/*.csv": true,
    "**/*.parquet": true
  },
  "python.analysis.indexing": false,
  "python.analysis.typeCheckingMode": "off",
  "python.analysis.diagnosticMode": "openFilesOnly",
  "git.autorefresh": false,
  "git.autofetch": false,
  "extensions.autoUpdate": false,
  "workbench.startupEditor": "none",
  "window.restoreWindows": "none"
}
KIT_EOF_15
mkdir -p "$T/services/Accentuer.workflow/Contents"
cat > "$T/services/Accentuer.workflow/Contents/Info.plist" <<'KIT_EOF_16'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>Accentuer</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
			<key>NSReturnTypes</key>
			<array>
				<string>public.utf8-plain-text</string>
			</array>
			<key>NSSendTypes</key>
			<array>
				<string>public.utf8-plain-text</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
KIT_EOF_16
mkdir -p "$T/services/Accentuer.workflow/Contents"
cat > "$T/services/Accentuer.workflow/Contents/document.wflow" <<'KIT_EOF_17'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AMApplicationBuild</key>
	<string>521.1</string>
	<key>AMApplicationVersion</key>
	<string>2.10</string>
	<key>AMDocumentVersion</key>
	<string>2</string>
	<key>actions</key>
	<array>
		<dict>
			<key>action</key>
			<dict>
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<true/>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>AMActionVersion</key>
				<string>2.0.3</string>
				<key>AMApplication</key>
				<array>
					<string>Automator</string>
				</array>
				<key>AMParameterProperties</key>
				<dict>
					<key>COMMAND_STRING</key>
					<dict/>
					<key>CheckedForUserDefaultShell</key>
					<dict/>
					<key>inputMethod</key>
					<dict/>
					<key>shell</key>
					<dict/>
					<key>source</key>
					<dict/>
				</dict>
				<key>AMProvides</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>ActionBundlePath</key>
				<string>/System/Library/Automator/Run Shell Script.action</string>
				<key>ActionName</key>
				<string>Run Shell Script</string>
				<key>ActionParameters</key>
				<dict>
					<key>COMMAND_STRING</key>
					<string>$HOME/.config/claude-launcher/accentuer.sh</string>
					<key>CheckedForUserDefaultShell</key>
					<true/>
					<key>inputMethod</key>
					<integer>0</integer>
					<key>shell</key>
					<string>/bin/zsh</string>
					<key>source</key>
					<string></string>
				</dict>
				<key>BundleIdentifier</key>
				<string>com.apple.RunShellScript</string>
				<key>CFBundleVersion</key>
				<string>2.0.3</string>
				<key>CanShowSelectedItemsWhenRun</key>
				<false/>
				<key>CanShowWhenRun</key>
				<true/>
				<key>Category</key>
				<array>
					<string>AMCategoryUtilities</string>
				</array>
				<key>Class Name</key>
				<string>RunShellScriptAction</string>
				<key>InputUUID</key>
				<string>3DA8DA68-BEF7-40EC-97F4-0628706A0CFA</string>
				<key>Keywords</key>
				<array>
					<string>Shell</string>
					<string>Script</string>
					<string>Command</string>
					<string>Run</string>
					<string>Unix</string>
				</array>
				<key>OutputUUID</key>
				<string>01E55BA0-4365-4087-A220-2C117A6E14EE</string>
				<key>UUID</key>
				<string>B0CA6460-F6D3-491C-BACF-E7B33EDDC43C</string>
				<key>UnlocalizedApplications</key>
				<array>
					<string>Automator</string>
				</array>
				<key>arguments</key>
				<dict>
					<key>0</key>
					<dict>
						<key>default value</key>
						<integer>0</integer>
						<key>name</key>
						<string>inputMethod</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>0</string>
					</dict>
					<key>1</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>source</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>1</string>
					</dict>
					<key>2</key>
					<dict>
						<key>default value</key>
						<false/>
						<key>name</key>
						<string>CheckedForUserDefaultShell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>2</string>
					</dict>
					<key>3</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>COMMAND_STRING</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>3</string>
					</dict>
					<key>4</key>
					<dict>
						<key>default value</key>
						<string>/bin/sh</string>
						<key>name</key>
						<string>shell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>4</string>
					</dict>
				</dict>
				<key>isViewVisible</key>
				<integer>1</integer>
				<key>location</key>
				<string>309.000000:253.000000</string>
				<key>nibPath</key>
				<string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
			</dict>
			<key>isViewVisible</key>
			<integer>1</integer>
		</dict>
	</array>
	<key>connectors</key>
	<dict/>
	<key>workflowMetaData</key>
	<dict>
		<key>applicationBundleIDsByPath</key>
		<dict/>
		<key>applicationPaths</key>
		<array/>
		<key>inputTypeIdentifier</key>
		<string>com.apple.Automator.text</string>
		<key>outputTypeIdentifier</key>
		<string>com.apple.Automator.text</string>
		<key>presentationMode</key>
		<integer>11</integer>
		<key>processesInput</key>
		<integer>0</integer>
		<key>serviceInputTypeIdentifier</key>
		<string>com.apple.Automator.text</string>
		<key>serviceOutputTypeIdentifier</key>
		<string>com.apple.Automator.text</string>
		<key>serviceProcessesInput</key>
		<integer>0</integer>
		<key>systemImageName</key>
		<string>NSActionTemplate</string>
		<key>useAutomaticInputType</key>
		<integer>0</integer>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.servicesMenu</string>
	</dict>
</dict>
</plist>
KIT_EOF_17
mkdir -p "$T/services/Launch idea.workflow/Contents"
cat > "$T/services/Launch idea.workflow/Contents/Info.plist" <<'KIT_EOF_18'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>Launch idea</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
			<key>NSSendTypes</key>
			<array>
				<string>public.utf8-plain-text</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
KIT_EOF_18
mkdir -p "$T/services/Launch idea.workflow/Contents"
cat > "$T/services/Launch idea.workflow/Contents/document.wflow" <<'KIT_EOF_19'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AMApplicationBuild</key>
	<string>521.1</string>
	<key>AMApplicationVersion</key>
	<string>2.10</string>
	<key>AMDocumentVersion</key>
	<string>2</string>
	<key>actions</key>
	<array>
		<dict>
			<key>action</key>
			<dict>
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<true/>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>AMActionVersion</key>
				<string>2.0.3</string>
				<key>AMApplication</key>
				<array>
					<string>Automator</string>
				</array>
				<key>AMParameterProperties</key>
				<dict>
					<key>COMMAND_STRING</key>
					<dict/>
					<key>CheckedForUserDefaultShell</key>
					<dict/>
					<key>inputMethod</key>
					<dict/>
					<key>shell</key>
					<dict/>
					<key>source</key>
					<dict/>
				</dict>
				<key>AMProvides</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>ActionBundlePath</key>
				<string>/System/Library/Automator/Run Shell Script.action</string>
				<key>ActionName</key>
				<string>Run Shell Script</string>
				<key>ActionParameters</key>
				<dict>
					<key>COMMAND_STRING</key>
					<string>$HOME/.config/claude-launcher/launch-idea.sh</string>
					<key>CheckedForUserDefaultShell</key>
					<true/>
					<key>inputMethod</key>
					<integer>0</integer>
					<key>shell</key>
					<string>/bin/zsh</string>
					<key>source</key>
					<string></string>
				</dict>
				<key>BundleIdentifier</key>
				<string>com.apple.RunShellScript</string>
				<key>CFBundleVersion</key>
				<string>2.0.3</string>
				<key>CanShowSelectedItemsWhenRun</key>
				<false/>
				<key>CanShowWhenRun</key>
				<true/>
				<key>Category</key>
				<array>
					<string>AMCategoryUtilities</string>
				</array>
				<key>Class Name</key>
				<string>RunShellScriptAction</string>
				<key>InputUUID</key>
				<string>B00ED692-0ED3-4045-B054-76AEE084ED66</string>
				<key>Keywords</key>
				<array>
					<string>Shell</string>
					<string>Script</string>
					<string>Command</string>
					<string>Run</string>
					<string>Unix</string>
				</array>
				<key>OutputUUID</key>
				<string>EF48BB8B-9D0C-4CCB-9657-1F295E822B4D</string>
				<key>UUID</key>
				<string>94F83D24-AB5E-4CCE-A2BD-26289B0D50CC</string>
				<key>UnlocalizedApplications</key>
				<array>
					<string>Automator</string>
				</array>
				<key>arguments</key>
				<dict>
					<key>0</key>
					<dict>
						<key>default value</key>
						<integer>0</integer>
						<key>name</key>
						<string>inputMethod</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>0</string>
					</dict>
					<key>1</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>source</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>1</string>
					</dict>
					<key>2</key>
					<dict>
						<key>default value</key>
						<false/>
						<key>name</key>
						<string>CheckedForUserDefaultShell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>2</string>
					</dict>
					<key>3</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>COMMAND_STRING</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>3</string>
					</dict>
					<key>4</key>
					<dict>
						<key>default value</key>
						<string>/bin/sh</string>
						<key>name</key>
						<string>shell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>4</string>
					</dict>
				</dict>
				<key>isViewVisible</key>
				<integer>1</integer>
				<key>location</key>
				<string>309.000000:253.000000</string>
				<key>nibPath</key>
				<string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
			</dict>
			<key>isViewVisible</key>
			<integer>1</integer>
		</dict>
	</array>
	<key>connectors</key>
	<dict/>
	<key>workflowMetaData</key>
	<dict>
		<key>applicationBundleIDsByPath</key>
		<dict/>
		<key>applicationPaths</key>
		<array/>
		<key>inputTypeIdentifier</key>
		<string>com.apple.Automator.text</string>
		<key>presentationMode</key>
		<integer>11</integer>
		<key>processesInput</key>
		<integer>0</integer>
		<key>serviceInputTypeIdentifier</key>
		<string>com.apple.Automator.text</string>
		<key>serviceProcessesInput</key>
		<integer>0</integer>
		<key>systemImageName</key>
		<string>NSActionTemplate</string>
		<key>useAutomaticInputType</key>
		<integer>0</integer>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.servicesMenu</string>
	</dict>
</dict>
</plist>
KIT_EOF_19
mkdir -p "$T/template"
cat > "$T/template/CLAUDE.md" <<'KIT_EOF_20'
# {{NAME}} (started {{DATE}})

## What this is
<!-- one or two lines: the idea, and what "done" looks like. Fill this in first message of the session if empty. -->

## Layout
- `notes/`: thinking, sources, drafts
- `data/raw/`: inputs — read-only
- `data/derived/`: anything computed from raw
- `output/`: figures, tables, exports
- `scripts/`: reusable code

## Working rules
- **Raw data is read-only.** Write derived data to `data/derived/`, results to `output/`.
- Stack: Python (pandas/polars), LaTeX.
- This is a scratch project: move fast, but keep a `notes/log.md` with one line per session so the thread can be picked up later.
- If this grows into a real project, say so and it gets moved out of `~/scratch` and renamed.
- **Ledger.** When a task is finished (a note drafted, a figure produced, an app deployed, an analysis run), append ONE line to `~/.config/claude-launcher/ledger/$(date +%G-W%V).md` in the form `- YYYY-MM-DD HH:MM | <project> | <what was done, one sentence, in French> | <links or file paths>`. Create the file if missing. This feeds the weekly memo; don't log exploration or failed attempts.
- **Cockpit.** If this session was started from a cockpit task (the prompt starts with "New task from my notes"), when the work is delivered run `python3 ~/.config/claude-launcher/cockpit.py done <id> --note "<one line>"` where `<id>` is the 6-character id in `notes/log.md` if present; if no id is there, skip this step.
KIT_EOF_20
mkdir -p "$T/template"
cat > "$T/template/scratch-CLAUDE.md" <<'KIT_EOF_21'
# ~/scratch — ideas and one-off experiments

Each subfolder is one idea, created with `cc new <name>` from `.template/`.
If a session starts here at the top level, ask which subfolder (or whether to create a new one) before doing anything.

## Working rules
- Raw data is read-only; derived data goes in `data/derived/`, results in `output/`.
- Stack: Python (pandas/polars), LaTeX.
- **Ledger.** When a task is finished (a note drafted, a figure produced, an app deployed, an analysis run), append ONE line to `~/.config/claude-launcher/ledger/$(date +%G-W%V).md` in the form `- YYYY-MM-DD HH:MM | <project> | <what was done, one sentence, in French> | <links or file paths>`. Create the file if missing. This feeds the weekly memo; don't log exploration or failed attempts.
- **Cockpit.** If this session was started from a cockpit task (the prompt starts with "New task from my notes"), when the work is delivered run `python3 ~/.config/claude-launcher/cockpit.py done <id> --note "<one line>"` where `<id>` is the 6-character id in `notes/log.md` if present; if no id is there, skip this step.
KIT_EOF_21
chmod +x "$T/install.sh" "$T"/launcher/*.sh "$T"/launcher/*.py "$T"/launcher/*.zsh 2>/dev/null || true
echo "→ running install.sh"
zsh "$T/install.sh"
echo
echo "Done. Open a new terminal window and type:  cc ls"
