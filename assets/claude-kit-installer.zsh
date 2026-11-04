#!/bin/zsh
# Research & organisation kit — one-paste installer (generated 2026-11-04).
# Writes the kit into ~/claude-kit, then runs its install.sh. Read it before running: everything it does is here.
set -e
T="$HOME/claude-kit"; mkdir -p "$T"
echo "→ writing kit files to $T"
cat > "$T/README.md" <<'KIT_EOF_0'
# Kit Claude — dicter, trier, exécuter

Une note par jour sur le téléphone, une commande sur le Mac : chaque ligne devient un rendez-vous, un rappel, ou une
session Claude Code qui travaille pendant que vous faites autre chose. Un cockpit tient la liste par priorité, une file
d'attente lance les sessions sans vous, un journal alimente le point hebdomadaire.

## Prérequis (10 min)
1. Un compte Claude (Pro ou Max) et l'application Claude pour Mac.
2. Claude Code : `curl -fsSL https://claude.ai/install.sh | bash`, puis `claude` une fois dans un terminal pour se connecter.
3. Homebrew (https://brew.sh) — le kit l'utilise pour installer `tmux` et `fzf`.

## Installation (5 min)
```
cd claude-kit && zsh install.sh
```
Puis, vous-même (l'installeur vous le rappelle) :
1. **Notes** : créer un dossier « Claude » et y mettre la note du jour. `cc` ne lit que ce dossier.
2. **Sécurité** : `python3 ~/.config/claude-launcher/merge-settings.py` (voir plus bas). Ne pas coller le fichier à la main.
3. Ouvrir un nouveau terminal : `cc ls` doit afficher `scratch`.

Tout est en zsh, le shell par défaut du Mac. Ne tapez pas `bash` : `cc` n'y existe pas.

## Premier usage
- Dans le dossier Notes « Claude », une note « to dos <date du jour> » avec trois lignes : un rendez-vous (« appel X
  jeudi 15h »), une relance (« envoyer le dossier à Y demain »), un sujet de fond (« préparer un script de 45 s sur … »).
- `cc inbox` → macOS demande les autorisations Notes, Calendrier, Rappels : accepter. Choisir le calendrier et la liste.
- Le rendez-vous est dans l'agenda, la relance dans Rappels, le sujet est ouvert dans une session Claude.
- `Ctrl-b d` détache la session (elle continue) ; `cc` pour y revenir.

## Écrire une ligne qui donne un résultat utilisable
Une session autonome fait ce que dit la ligne. Règle : **un verbe, une entrée, une sortie**. « recap réunion » donne un
résultat vague ; « écrire le récap de la réunion du 3 nov à partir de mes notes, 1 page, dans output/ » donne un
résultat utilisable. `cc inbox` réécrit chaque ligne dans ce format et signale ce qui manque (« [entrée ?] »).

## Vos projets, et vos conversations existantes
- **Un `CLAUDE.md` par projet.** Dans chaque dossier de travail : `cd` dedans, `cc add`, puis dans la session Claude :
  « écris le CLAUDE.md de ce projet : ce que c'est, où sont les sources, les règles ». Toute nouvelle session le lit
  d'elle-même : le contexte n'est jamais à réexpliquer.
- **Vos conversations Claude Code dans VS Code sont conservées** sur le disque, par dossier de projet. Pour en
  reprendre une depuis le terminal : `cc <nom> -c` (la dernière conversation de ce dossier), ou `cd` dedans puis
  `claude --resume` pour choisir dans la liste. Fermer VS Code ne perd rien, sauf ce qui tournait à ce moment-là :
  laissez finir ou détachez avant de fermer.
- Une conversation dans l'application Claude (claude.ai) et une session Claude Code sont deux choses séparées : la
  mémoire de l'une n'est pas celle de l'autre. Côté terminal, ce sont les `CLAUDE.md` qui tiennent le contexte.

## Le cockpit et la file d'attente
- `cc cockpit` affiche `~/scratch/COCKPIT.md` : tâches par priorité (P1 d'abord), ce qui attend une réponse de vous,
  sessions en cours, journal du jour, messages à envoyer. État d'une tâche : *à faire*, *en cours*, *à relire* (la
  session a fini : regarder son dossier `output/`), *toi* (à faire vous-même), close.
- `cc run` (ou `cc run P1`) met toutes les tâches ouvertes dans la file ; le runner (launchd, toutes les 60 s) en lance
  au plus 3 à la fois, P1 d'abord, chacune comme une session `claude -p` sans surveillance, dans le dossier du projet
  si la tâche en a un (`output/<id>/`), sinon dans un dossier de `~/scratch`. Le Mac reste éveillé 3 h.
- `cc me <id>` marque une tâche comme vôtre (envoyer, appeler, décider) : la file ne la donne jamais à une session.
- `cc clean` ferme les sessions terminées ; `cc reset` remet à faire les tâches dont la session a disparu.
- Une session terminée garde un terminal ouvert dans son dossier : `cc <nom>` pour y aller, `claude -c` pour continuer
  la conversation avec elle.
- Suivre : `cc ls` (`*` = en cours), `tail -f ~/scratch/.queue/done/queue.log`, ou plus simple :
  `cd ~/scratch && claude` puis « où en est la file ? ».

## Depuis le téléphone
Tout ce qui peut écrire un fichier dans `~/scratch/.queue/` donne du travail au Mac : un fichier `<nom>.task` (une
ligne de tâche), `<nom>.cmd` (une commande `cc`, ex. `run`), ou un fichier vide `INBOX` (trier la note du jour). Avec
l'application Claude reliée au Mac (dossiers `~/scratch` et `~/.config/claude-launcher` connectés), il suffit d'écrire
dans la conversation « mets en file : … » ou « inbox ». Les messages préparés sont dans Rappels › Comms : à modifier et
envoyer depuis le téléphone.

## Sécurité
Quatre couches, chacune indépendante. Rien ne part sans vous : les messages restent des brouillons, aucune session
n'envoie, ne publie, ne pousse sur GitHub ni ne supprime.
- **Notes** : seul le dossier « Claude » est lu (`CC_NOTES_FOLDER` dans `~/.config/claude-launcher/config.json`) ;
  une note verrouillée n'est jamais lue ; une ligne qui commence par 🔒, `privé` ou `//` est ignorée.
- **Disque** : la sandbox de Claude Code (Seatbelt, imposée par macOS) limite l'écriture au dossier du projet (+ journal,
  cockpit, file) et interdit la lecture de `~/.ssh`, des trousseaux, cookies, mails, messages, fichiers `.env` et clés,
  et toute écriture dans un dossier `raw/`. `~/Library/CloudStorage` (Dropbox, iCloud Drive…) reste lisible.
- **Réseau** : les commandes ne joignent qu'une liste courte de domaines ; la recherche web passe par les outils de
  Claude, limités à des sources de référence (à compléter dans `permissions.allow`).
- **Secrets** : clés d'API dans le Trousseau macOS, pas en clair sur le disque :
  `security add-generic-password -a "$USER" -s <service> -T /usr/bin/security -U -w` (le `-T` évite la fenêtre de mot
  de passe à chaque lecture ; sinon cliquer « Toujours autoriser » une fois).

Installer : `python3 ~/.config/claude-launcher/merge-settings.py`. Le script sauvegarde `~/.claude/settings.json`,
refuse un fichier déjà invalide (en indiquant la ligne), garde toutes vos règles, ajoute les protections, et valide le
résultat. Le mode des sessions autonomes est `acceptEdits` (éditions de fichiers et bash dans la sandbox : oui ; tout
le reste : refusé plutôt que demandé). `"CC_QUEUE_PERMISSIONS": "skip"` dans `config.json` les rend entièrement libres :
seulement avec la sandbox active.

## Chaque semaine
`cc memo` compile le journal des sessions en point hebdomadaire ; `cc memo --message` en tire le message de groupe
(demandes nominatives et datées, copié dans le presse-papiers) et les relances à coller dans la note du jour.

## Commandes
```
cc                  choisir un projet, reprendre sa session      cc <nom> -c      reprendre la dernière conversation
cc new <nom>        nouveau projet dans ~/scratch                cc ls / cc add   registre des projets (* = en cours)
cc today            lancer un sujet de la note du jour           cc inbox         trier la note : agenda / rappels / sessions
cc cockpit          la liste par priorité                        cc run [P1]      tout lancer via la file, P1 d'abord
cc me <id>          tâche à faire soi-même                       cc clean         fermer les sessions terminées
cc reset [id]       remettre à faire                             cc queue "…"     une tâche dans la file
cc comms            messages préparés → Rappels « Comms »        cc memo          point hebdomadaire (--message)
cc tri / note / evalue   optionnel : trier ou écrire des notes selon votre propre standard ($CC_KIT, un fichier .md)
```
Fichiers : `~/.config/claude-launcher/` (lanceur, scripts, `projects.txt`, `config.json`, `ledger/`), `~/scratch/`
(projets, `COCKPIT.md`, `.cockpit/`, `.queue/`), `~/Library/Services/`.

## Si ça bloque
| Symptôme | Cause et remède |
| --- | --- |
| `zsh: command not found: cc` | `source ~/.config/claude-launcher/cc.zsh`, ou ouvrir un nouveau terminal (zsh, pas bash) |
| `launchctl list \| grep cc-queue` montre `126` | un script a perdu son droit d'exécution : `chmod +x ~/.config/claude-launcher/*.zsh`, puis relancer `zsh install.sh` |
| Claude Code : « settings.json invalid JSON » | souvent un `{ ... }` collé à la main : corriger la ligne indiquée, puis `merge-settings.py` |
| La file se vide mais rien n'est produit | `tail ~/scratch/.queue/done/queue.log` et le `notes/run-*.log` du dossier de la tâche |
| Fenêtre « security veut utiliser le trousseau » | cliquer « Toujours autoriser », ou recréer la clé avec `-T /usr/bin/security` |
| Une tâche reste vague | réécrire la ligne : verbe + entrée + sortie, puis `cc reset <id>` et `cc run` |

Sinon : ouvrir une conversation Claude dans l'application Mac, autoriser le dossier du kit, et dire :
« finis l'installation du kit Claude qui est dans ~/claude-kit ».
KIT_EOF_0
cat > "$T/install.sh" <<'KIT_EOF_1'
#!/bin/zsh
# Installation du kit Claude (lanceur cc, Notes → agenda/rappels/terminal, cockpit, file d'attente, mémo, actions rapides).
# Idempotent : on peut le relancer pour mettre à jour ; vos registre, config et réglages Claude Code ne sont pas écrasés.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
L="$HOME/.config/claude-launcher"
echo "→ lanceur dans $L"
mkdir -p "$L/ledger"
cp "$HERE"/launcher/{cc.zsh,notes_ideas.py,inbox.py,memo.py,cockpit.py,comms.py,accentuer.sh,launch-idea.sh,queue-runner.zsh,com.cc-queue.plist,vscode_settings_snippet.json,merge-settings.py,security-settings-snippet.json,config-snippet.json} "$L/"
[[ -f "$L/projects.txt" ]] || cp "$HERE/launcher/projects.txt" "$L/"
[[ -f "$L/config.json" ]] || cp "$HERE/launcher/config-snippet.json" "$L/config.json"
chmod +x "$L"/*.sh "$L"/*.py "$L"/*.zsh
echo "→ dossier scratch, modèle de projet, cockpit"
mkdir -p "$HOME/scratch/.template" "$HOME/scratch/.memo" "$HOME/scratch/.cockpit/import" "$HOME/scratch/.queue/done" "$HOME/scratch/.queue/running"
cp "$HERE/template/CLAUDE.md" "$HOME/scratch/.template/CLAUDE.md"
[[ -f "$HOME/scratch/CLAUDE.md" ]] || cp "$HERE/template/scratch-CLAUDE.md" "$HOME/scratch/CLAUDE.md"
echo "→ actions rapides (Services)"
mkdir -p "$HOME/Library/Services"
cp -R "$HERE"/services/*.workflow "$HOME/Library/Services/"
/System/Library/CoreServices/pbs -update 2>/dev/null || true
echo "→ tmux et fzf"
[[ -f "$HOME/.tmux.conf" ]] || cp "$HERE/launcher/tmux.conf" "$HOME/.tmux.conf"
if command -v brew >/dev/null 2>&1; then
  brew list tmux >/dev/null 2>&1 || brew install tmux
  brew list fzf  >/dev/null 2>&1 || brew install fzf
else
  echo "   Homebrew absent : installez-le (https://brew.sh) puis : brew install tmux fzf"
fi
echo "→ .zshrc"
grep -q 'claude-launcher/cc.zsh' "$HOME/.zshrc" 2>/dev/null || printf '\n# Claude launcher\nsource ~/.config/claude-launcher/cc.zsh\n' >> "$HOME/.zshrc"
echo "→ file d'attente (queue runner, toutes les 60 s)"
mkdir -p "$HOME/Library/LaunchAgents"
sed "s|\$HOME|$HOME|g" "$L/com.cc-queue.plist" > "$HOME/Library/LaunchAgents/com.cc-queue.plist"
launchctl unload "$HOME/Library/LaunchAgents/com.cc-queue.plist" 2>/dev/null || true
launchctl load "$HOME/Library/LaunchAgents/com.cc-queue.plist" 2>/dev/null && echo "   queue runner chargé"
if ! command -v claude >/dev/null 2>&1; then
  echo
  echo "   Claude Code n'est pas installé : curl -fsSL https://claude.ai/install.sh | bash   puis lancez 'claude' une fois."
fi
echo
echo "Terminé. Trois étapes restent à faire vous-même (README, « Sécurité ») :"
echo "  1. Notes : créer un dossier « Claude » et y mettre la note du jour — cc ne lit que ce dossier."
echo "  2. Sandbox Claude Code (recommandé avant toute session autonome) :"
echo "       python3 ~/.config/claude-launcher/merge-settings.py"
echo "     (sauvegarde ~/.claude/settings.json, garde vos règles, ajoute les protections ; ne pas coller le snippet à la main)"
echo "  3. Ouvrir un nouveau terminal :  cc ls"
echo "Mode d'emploi : $HERE/README.md"
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
#   cc clean           close sessions whose claude has finished (pane back to a shell)
#   cc reset [id...]   put tasks back to « à faire » (default: running ones whose session is gone)
#   cc me <id>...      mark tasks as yours (send, call, decide): cc run never gives them to a session
#   cc tri <lot.md>    sort a batch of received notes with your writing kit (optional, see CC_KIT) → ~/scratch/.tri/
#   cc note "sujet"    open a session that writes a note to your writing kit's standard (optional, see CC_KIT)
#   cc evalue <note.md> score a note /10 against your writing kit, three corrections (optional, see CC_KIT)
#   cc run [P1]        launch every open cockpit task (optionally only P1) through the queue, detached
#   cc cockpit         rebuild and show ~/scratch/COCKPIT.md (tasks, sessions, journal, queue)
#   cc comms [sync|list|suggest|done <id>]   the comms bank → Reminders list "Comms" (edit, copy, send from phone or Mac)
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
# CC_KIT: optional markdown file holding your house standard for notes (structure, grid, rules) used by cc tri/note/evalue
CC_KIT="${CC_KIT:-$HOME/.config/claude-launcher/kit/writing-kit.md}"

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
    # claude is the session's own command (typing it into a fresh shell can be lost while the shell starts);
    # when claude exits, a shell stays open in the folder. Arguments arrive already quoted by the caller.
    local cl="${commands[claude]:-claude}"
    tmux new-session -d -s "$sess" -c "$dir" "${(qq)cl} $*; exec ${SHELL:-/bin/zsh} -l"
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
        printf '%s\n' "$text" > "$CC_SCRATCH/.queue/$tid.task"; n=$((n+1))
      done
      python3 "$CC_COCKPIT_PY" refresh >/dev/null
      if (( n > 0 )); then
        # keep the Mac awake for 3 h so the queue runner can work through the list while you are away
        command -v caffeinate >/dev/null && { caffeinate -dims -t 10800 >/dev/null 2>&1 &! ; echo "(Mac kept awake for 3 h)"; }
        launchctl list 2>/dev/null | grep -q cc-queue || echo "WARNING: the queue runner is not loaded — run: zsh ~/.config/claude-launcher/install-services.sh"
      fi
      echo "queued $n task(s) in priority order; the runner starts up to $(python3 -c 'import json;print(json.load(open("'"$HOME"'/.config/claude-launcher/config.json")).get("CC_QUEUE_MAX_RUN",3))' 2>/dev/null || echo 3) at a time, P1 first" ;;
    comms)
      shift; python3 "$HOME/.config/claude-launcher/comms.py" "${@:-sync}" ;;
    cockpit)
      python3 "$CC_COCKPIT_PY" refresh >/dev/null; cat "$CC_SCRATCH/COCKPIT.md" ;;
    memo)
      shift; python3 "$CC_MEMO_PY" "$@" ;;
    queue)
      shift; mkdir -p "$CC_SCRATCH/.queue"
      [[ "$1" == "inbox" ]] && { touch "$CC_SCRATCH/.queue/INBOX"; echo "queued: inbox"; return; }
      print -r -- "$*" > "$CC_SCRATCH/.queue/$(date +%s).task"; echo "queued: $*" ;;
    tri)
      [[ -r "$CC_KIT" ]] || { echo "cc: no writing kit at $CC_KIT (put your standard there, or export CC_KIT=...)" >&2; return 1; }
      # cc tri <fichier-du-lot> [actualité]  — tri d'un lot de notes selon votre kit d'écriture ($CC_KIT)
      shift; local lot="$1"; [[ -r "$lot" ]] || { echo "usage: cc tri <fichier contenant les notes du lot> [actualité]" >&2; return 1; }
      shift; local actu="$*"; mkdir -p "$CC_SCRATCH/.tri"
      local out="$CC_SCRATCH/.tri/tri-$(date +%F).md"
      { cat "$CC_KIT"; echo; echo "## Lot du $(date +%F)"; [[ -n "$actu" ]] && echo "actualité : $actu"; echo; cat "$lot"; } \
        | claude -p "Tu es l'assistant du module 1 (tri des notes). Applique la commande « tri » au lot ci-dessous : sections 1, 2 et 6, puis « transmission » (section 4). Le registre des destinataires est l'annexe C ; s'il dit « À compléter », écris « destinataire à choisir ». Réponds en markdown, sans préambule." > "$out"
      echo "tri écrit dans $out"; ${PAGER:-less} "$out" ;;
    note)
      [[ -r "$CC_KIT" ]] || { echo "cc: no writing kit at $CC_KIT (put your standard there, or export CC_KIT=...)" >&2; return 1; }
      # cc note "sujet, destinataire"  — module 2 du kit: une session qui rédige une note percutante
      shift; [[ -z "$*" ]] && { echo 'usage: cc note "sujet, destinataire (rôle), format"' >&2; return 1; }
      _cc_from_text "" "[note] Rédiger une note percutante : $* — suivre le module 2 (« rédige ») du kit $CC_KIT, écrire la note dans output/note.md, terminer par l'auto-évaluation /10" ;;
    evalue)
      [[ -r "$CC_KIT" ]] || { echo "cc: no writing kit at $CC_KIT (put your standard there, or export CC_KIT=...)" >&2; return 1; }
      # cc evalue <fichier.md>  — module 2 « évalue »: grille /10 et trois corrections, sans réécrire
      shift; [[ -r "$1" ]] || { echo "usage: cc evalue <note.md>" >&2; return 1; }
      { cat "$CC_KIT"; echo; echo "## Note à évaluer"; echo; cat "$1"; } \
        | claude -p "Applique la commande « évalue » du module 2 à la note ci-dessous : tableau critère/note/phrase/reformulation, score sur 10 et verdict, trois corrections prioritaires. Ne réécris pas la note. Markdown, sans préambule." ;;
    clean)
      # close the tmux sessions whose claude has ended (the pane is back to a shell); running ones are kept
      local s c k=0
      tmux list-panes -a -F '#{session_name} #{pane_current_command}' 2>/dev/null | while read -r s c; do
        case "$c" in zsh|-zsh|bash|-bash|sh) tmux kill-session -t "=$s" && echo "closed $s" && k=$((k+1)) ;; esac
      done
      python3 "$CC_COCKPIT_PY" refresh >/dev/null ;;
    reset)
      # cc reset [id...]: back to « à faire » (default: tasks marked running/à relire whose session is gone)
      shift; python3 "$CC_COCKPIT_PY" reset "$@"; python3 "$CC_COCKPIT_PY" refresh >/dev/null ;;
    me)
      # cc me <id>...: tasks only you can do (send, call, decide) — cc run and the runner skip them
      shift; python3 "$CC_COCKPIT_PY" me "$@"; python3 "$CC_COCKPIT_PY" refresh >/dev/null ;;
    kill)
      local d; d=$(_cc_path_for "$2") || { echo "cc: unknown project '$2'" >&2; return 1; }
      tmux kill-session -t "=$(_cc_session_name "$d")" ;;
    help|-h|--help) sed -n '2,34p' "${(%):-%x}" ;;
    *)
      local d; d=$(_cc_path_for "$cmd") || { echo "cc: unknown project '$cmd' (try: cc ls)" >&2; return 1; }
      shift; _cc_launch "$d" "$@" ;;
  esac
}

# tab completion for project names
if (( $+functions[compdef] )); then
  _cc() { local -a names; names=(new idea today inbox run cockpit comms memo queue add ls kill x "${(@f)$(_cc_names)}"); _describe 'project' names; }
  compdef _cc cc
fi
KIT_EOF_3
mkdir -p "$T/launcher"
cat > "$T/launcher/cockpit.py" <<'KIT_EOF_4'
#!/usr/bin/env python3
"""cockpit.py — the local source of truth for everything in flight, rebuilt as ~/scratch/COCKPIT.md.

  cockpit.py add  --p P1|P2|P3 --text "..." [--project NAME] [--link URL] [--source inbox]   add a task
  cockpit.py start  <id> [--session NAME]      mark running (done by cc / queue runner)
  cockpit.py done   <id> [--note "..."]        mark done (the session calls this when it delivers)
  cockpit.py review <id> [--note "..."]        session ended without `done`: output to check (queue runner)
  cockpit.py reset  [id...]                    back to todo (default: running/review tasks whose session is gone)
  cockpit.py me     <id>...                    yours only (send, call, decide): `next` / `cc run` skip it
  cockpit.py field  <id> <key>                 print one field
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


def import_drops(st):
    """Merge ~/scratch/.cockpit/import/*.json (written from chat): {"tasks":[..],"waiting":[..],"messages":[..]}.
    Idempotent: items whose id already exists are skipped. Processed files move to import/done/. Messages go to comms.json."""
    imp = f"{DIR}/import"
    files = sorted(glob.glob(f"{imp}/*.json"))
    if not files:
        return 0
    os.makedirs(f"{imp}/done", exist_ok=True)
    ids = {t["id"] for t in st["tasks"]} | {w["id"] for w in st["waiting"]}
    n = 0
    for f in files:
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        for t in d.get("tasks", []):
            if t.get("id") in ids or not t.get("text"):
                continue
            t.setdefault("status", "todo"); t.setdefault("p", "P2"); t.setdefault("added", now()); t.setdefault("source", "import")
            st["tasks"].append(t); ids.add(t["id"]); n += 1
        for w in d.get("waiting", []):
            if w.get("id") in ids or not w.get("text"):
                continue
            w.setdefault("added", now()); st["waiting"].append(w); ids.add(w["id"]); n += 1
        if d.get("unwait"):
            st["waiting"] = [w for w in st["waiting"] if w["id"] not in set(d["unwait"])]; n += 1
        for b in d.get("bump", []) + d.get("set", []):
            for t in st["tasks"]:
                if t["id"] == b.get("id"):
                    for k in ("p", "text", "who", "status", "project", "link", "dirs"):
                        if k in b and (k != "p" or b[k] in PRIO):
                            t[k] = b[k]
                    n += 1
        if d.get("messages"):
            cpath = f"{DIR}/comms.json"
            try:
                bank = json.load(open(cpath, encoding="utf-8"))
            except Exception:
                bank = {"messages": []}
            have = {m["id"] for m in bank["messages"]}
            for m in d["messages"]:
                if m.get("id") in have:
                    continue
                m.setdefault("status", "draft"); m.setdefault("added", now()); m.setdefault("p", "P2")
                bank["messages"].append(m); have.add(m["id"]); n += 1
            json.dump(bank, open(cpath, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
        os.replace(f, f"{imp}/done/{os.path.basename(f)}")
    if n:
        save(st)
    return n


def refresh(st):
    import_drops(st)
    opn = sorted([t for t in st["tasks"] if t["status"] in ("todo", "running", "review")],
                 key=lambda t: (PRIO.get(t["p"], 9), t.get("who") != "me", t["added"]))
    done = [t for t in st["tasks"] if t["status"] == "done" and t.get("done_at", "").startswith(dt.date.today().isoformat())]
    sess = tmux_sessions()
    L = [f"# COCKPIT — {now()}", "",
         "Source de vérité locale. `cc inbox` ajoute, `cc run` lance, les sessions écrivent le journal, `cockpit.py refresh` recompose. Claude (chat) reflète ce fichier dans le doc Cockpit.", "",
         "## Aujourd'hui, par priorité", "",
         "| id | P | Quoi | État | Projet / lien |", "| --- | --- | --- | --- | --- |"]
    for t in opn:
        link = t.get("link") or t.get("project") or ""
        state = {"todo": "à faire", "running": "en cours", "review": "à relire"}.get(t["status"], t["status"])
        if t.get("who") == "me" and t["status"] == "todo":
            state = "toi"
        if t.get("session") and t["status"] in ("running", "review"):
            state += f" ({t['session']})"
        if t["status"] == "review" and t.get("note"):
            state += f" — {t['note']}"
        L.append(f"| {t['id']} | {t['p']} | {t['text']} | {state} | {link} |")
    L += ["", "## En attente de toi", ""]
    for w in st["waiting"]:
        L.append(f"- [ ] ({w['id']}) {w['text']}")
    L += ["", "## En cours (sessions tmux)", ""]
    for n, c in sess:
        L.append(f"- {n} — depuis {c}")
    L += ["", "## Terminé aujourd'hui (journal des sessions)", ""] + (ledger_today() or ["- (rien encore)"])
    L += ["", "## Tâches closes aujourd'hui", ""] + ([f"- {t['text']} ({t.get('note','')})" for t in done] or ["- (rien encore)"])
    L += ["", "## File d'attente (queue runner)", ""] + ([f"- {q}" for q in queue_today()] or ["- (rien)"])
    # comms bank + who to contact
    try:
        bank = json.load(open(f"{DIR}/comms.json"))["messages"]
        pend = sorted([m for m in bank if m["status"] != "sent"], key=lambda m: (PRIO.get(m["p"], 9), m.get("added", "")))
        L += ["", "## Messages à envoyer (banque de comms, dans Rappels « Comms »)", ""] + ([f"- {m['p']} · {m['via']} · {m['to']} — {m['subject']}" for m in pend] or ["- (rien)"])
    except Exception:
        pass
    try:
        r = subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "comms.py"), "suggest"], capture_output=True, text=True)
        L += ["", "## Qui contacter, d'après les tâches ouvertes", ""] + (r.stdout.strip().splitlines() or ["- (rien)"])
    except Exception:
        pass
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
            if t["id"] == a[1] and t["status"] != "done":
                t["status"] = "running"; t["session"] = arg(a, "--session", ""); t["started"] = now()
        save(st)
    elif cmd == "done":
        for t in st["tasks"]:
            if t["id"] == a[1]:
                t["status"] = "done"; t["done_at"] = now(); t["note"] = arg(a, "--note", "")
        save(st)
    elif cmd == "review":
        # the session ended without calling `done`: its output needs your eyes
        for t in st["tasks"]:
            if t["id"] == a[1] and t["status"] != "done":
                t["status"] = "review"; t["ended"] = now(); t["note"] = arg(a, "--note", "")
        save(st)
    elif cmd == "reset":
        # reset [id...]: back to "todo" (default: every running/review task whose session is gone)
        alive = {n for n, _ in tmux_sessions()}
        ids = set(a[1:])
        k = 0
        for t in st["tasks"]:
            if (t["id"] in ids) or (not ids and t["status"] in ("running", "review") and t.get("session") not in alive):
                t["status"] = "todo"; t.pop("session", None); k += 1
        save(st); print(f"{k} task(s) back to todo")
    elif cmd == "me":
        # me <id>...: tasks only you can do (send, call, decide); never given to a session
        for t in st["tasks"]:
            if t["id"] in a[1:]:
                t["who"] = "me"
        save(st)
    elif cmd == "field":
        # field <id> <key>: print one field (used by the queue runner)
        for t in st["tasks"]:
            if t["id"] == a[1]:
                print(t.get(a[2]) or ""); break
        return
    elif cmd == "wait":
        w = {"id": uuid.uuid4().hex[:6], "text": arg(a, "--text", ""), "added": now()}
        st["waiting"].append(w); save(st); print(w["id"])
    elif cmd == "unwait":
        st["waiting"] = [w for w in st["waiting"] if w["id"] != a[1]]; save(st)
    elif cmd == "next":
        p = arg(a, "--p")
        for t in sorted([t for t in st["tasks"] if t["status"] == "todo" and t.get("who") != "me" and (not p or t["p"] == p)],
                        key=lambda t: (PRIO.get(t["p"], 9), t["added"])):
            print(f"{t['id']}\t{t['p']}\t{t['text']}")
        return
    elif cmd == "order":
        # order <file>...  → the same files, sorted by the priority of the cockpit id in their name (unknown → P2), then by name
        pr = {t["id"]: PRIO.get(t["p"], 1) for t in st["tasks"]}
        def key(f):
            b = os.path.basename(f).split(".")[0]
            return (pr.get(b, 1), b)
        for f in sorted(a[1:], key=key):
            print(f)
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
  <array><string>/bin/zsh</string><string>-lc</string><string>zsh "$HOME/.config/claude-launcher/queue-runner.zsh"</string></array>
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
  comms.py add --p P1 --to "Nom" --via whatsapp|email|slack --subject "..." --body "..." [--topic projet-x]
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
cat > "$T/launcher/config-snippet.json" <<'KIT_EOF_7'
{
 "CC_NOTES_FOLDER": "Claude",
 "CC_QUEUE_MAX_RUN": 3,
 "CC_QUEUE_PERMISSIONS": "acceptEdits"
}
KIT_EOF_7
mkdir -p "$T/launcher"
cat > "$T/launcher/inbox.py" <<'KIT_EOF_8'
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
  "kind":     for tasks only: "note" (a policy note, brief or talking points), "riposte" (a rebuttal of someone else's claim), "other"
  "task":     for tasks only: the line rewritten as an operational instruction — verb + input + output
              (e.g. "Écrire le récap de la réunion du 3 nov à partir de mes notes, 1 page, dans output/").
              Keep the author's words; if the input or the output is not in the line, write "[entrée ?]" / "[sortie ?]" in its place.

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
                # Operational rewrite (verb + input + output) and kind tag go AFTER the dictated line,
                # so the zsh wrapper can still tick the original line in the note (it marks text before the first " — ").
                kind = it.get("kind") or "other"
                tag = {"note": "[note] ", "riposte": "[riposte] "}.get(kind, "")
                op = (it.get("task") or "").strip()
                if op and op != it["line"]:
                    text = it["line"] + " — ⇒ " + tag + op + (text[len(it["line"]):] if text.startswith(it["line"]) else "")
                elif tag:
                    text = it["line"] + " — ⇒ " + tag.strip() + (text[len(it["line"]):] if text.startswith(it["line"]) else "")
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
cat > "$T/launcher/merge-settings.py" <<'KIT_EOF_11'
#!/usr/bin/env python3
"""Merge the security snippet into ~/.claude/settings.json — safely.

  python3 ~/.config/claude-launcher/merge-settings.py [snippet.json]

- backs up the current file to settings.json.bak-<date-time> first;
- refuses to touch a file that is not valid JSON (it says where it breaks: fix that first);
- deep-merges: your existing keys and rules are kept, lists are unioned, nothing of yours is replaced;
- removes over-broad rules of earlier versions of the snippet (all of ~/Library), which also blocked
  Dropbox and other cloud folders (~/Library/CloudStorage);
- validates the result before writing it.
"""
import datetime, json, os, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SNIP = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "security-settings-snippet.json")
DEST = os.path.expanduser("~/.claude/settings.json")
OBSOLETE = {"Read(~/Library/**)", "~/Library"}


def merge(a, b):
    if isinstance(a, dict) and isinstance(b, dict):
        out = dict(a)
        for k, v in b.items():
            out[k] = merge(a[k], v) if k in a else v
        return out
    if isinstance(a, list) and isinstance(b, list):
        return [x for x in a if x not in OBSOLETE] + [x for x in b if x not in a]
    return a  # a scalar you already set wins


def main():
    snippet = json.load(open(SNIP, encoding="utf-8"))
    cur = {}
    if os.path.exists(DEST):
        txt = open(DEST, encoding="utf-8").read()
        try:
            cur = json.loads(txt) if txt.strip() else {}
        except json.JSONDecodeError as e:
            sys.exit(f"{DEST} is not valid JSON (line {e.lineno}, column {e.colno}: {e.msg}).\n"
                     f"Fix that line first (a pasted '{{ ... }}' placeholder is the usual cause), then rerun.")
        bak = f"{DEST}.bak-{datetime.datetime.now():%Y%m%d-%H%M%S}"
        shutil.copy2(DEST, bak)
        print(f"backup: {bak}")
    new = merge(cur, snippet)
    json.loads(json.dumps(new))
    os.makedirs(os.path.dirname(DEST), exist_ok=True)
    json.dump(new, open(DEST, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    p = new.get("permissions", {})
    print(f"ok: {DEST} — {len(p.get('allow', []))} allow, {len(p.get('ask', []))} ask, {len(p.get('deny', []))} deny rules; "
          f"sandbox {'on' if new.get('sandbox', {}).get('enabled') else 'off'}. Restart open Claude Code sessions.")


if __name__ == "__main__":
    main()
KIT_EOF_11
mkdir -p "$T/launcher"
cat > "$T/launcher/notes_ideas.py" <<'KIT_EOF_12'
#!/usr/bin/env python3
"""Bridge between Apple Notes and the cc launcher.

  notes_ideas.py list   [--note TITLE]          -> prints open to-do lines, one per line
  notes_ideas.py mark   [--note TITLE] LINE     -> prefixes LINE with a check mark in the note
  notes_ideas.py notes                          -> prints all note titles (to find the right one)
  notes_ideas.py today-note                     -> title of today's note (date in title > created today > modified today)
  notes_ideas.py today                          -> title of today's note, then its open to-do lines
  notes_ideas.py slug   TEXT                    -> prints a folder-safe slug for TEXT

Default note title: $CC_NOTE or "Ideas". Only notes in the folder CC_NOTES_FOLDER (default "Claude") are read/written;
locked (password-protected) notes are never read; a line starting with 🔒, privé, private or // is skipped.
"""
import html, os, re, subprocess, sys, unicodedata

DONE_MARKS = ("✅", "✓", "☑", "📅", "⏰", "[x]", "[X]", "- [x]")
PRIVATE_MARKS = ("🔒", "privé", "private", "//")  # a line starting with one of these is never read by cc nor sent to Claude


def notes_folder():
    """Only this Notes folder is ever read or written (config.json CC_NOTES_FOLDER, env override; default "Claude").
    Set it to "" to allow every folder (not recommended)."""
    if "CC_NOTES_FOLDER" in os.environ:
        return os.environ["CC_NOTES_FOLDER"]
    try:
        import json
        return json.load(open(os.path.expanduser("~/.config/claude-launcher/config.json"))).get("CC_NOTES_FOLDER", "Claude")
    except Exception:
        return "Claude"


def _scope(script):
    """`every note` → notes of the allowed folder only, never password-protected ones."""
    f = notes_folder()
    src = f'every note of folder "{f}"' if f else "every note"
    out = script.replace("every note whose", src + " whose password protected is false and")
    out = out.replace("every note)", src + " whose password protected is false)")
    out = out.replace("name of every note", "name of (" + src + " whose password protected is false)")
    return out


def osascript(script, *args):
    script = _scope(script)
    r = subprocess.run(["osascript", "-"] + list(args), input=script, text=True, capture_output=True)
    if r.returncode != 0 and "folder" in r.stderr and notes_folder():
        sys.exit(f"osascript failed: {r.stderr.strip()}\n→ cc only reads the Notes folder '{notes_folder()}'. Create it in Notes and move today's note there (or change CC_NOTES_FOLDER in config.json).")
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
        if s.startswith(DONE_MARKS) or s.lower().startswith(PRIVATE_MARKS):
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
KIT_EOF_12
mkdir -p "$T/launcher"
cat > "$T/launcher/projects.txt" <<'KIT_EOF_13'
# Registre des projets — une ligne par projet : <nom><TAB><chemin>
# `cc add` enregistre le dossier courant ; `cc new <nom>` crée un projet dans ~/scratch.
scratch	~/scratch
KIT_EOF_13
mkdir -p "$T/launcher"
cat > "$T/launcher/queue-runner.zsh" <<'KIT_EOF_14'
#!/bin/zsh
# Queue runner — launchd runs it every 60 s (com.*.cc-queue). Anything that can write a file can give the Mac work:
#   ~/scratch/.queue/<id>.task   text = a task line → a headless Claude session in tmux (detached), see below
#   ~/scratch/.queue/<name>.cmd  text = a cc command, e.g. "run" or "memo --message"; run once inside tmux
#   ~/scratch/.queue/INBOX       runs the inbox sort (no confirmation) once, then deletes the flag
# Processed files move to ~/scratch/.queue/done/; everything is logged in done/queue.log.
#
# Tasks:
# - start in cockpit priority order (P1 first), at most CC_QUEUE_MAX_RUN at once (config.json, default 3);
#   tasks marked as yours (cockpit.py me <id>) or already done are skipped;
# - <id>.task with a 6-character cockpit id runs in the task's project folder when its project is in the registry
#   (projects.txt), writing to output/<id>/; otherwise in a scratch folder, reused if one exists for that id;
# - each session is `claude -p` (headless: it works end to end and exits; nothing to answer) run as the tmux session's
#   own command — no keystrokes are typed into a shell — and writes an exit marker when it ends. The pane then stays
#   open on a shell in that folder: attach with `cc <session>` and type `claude -c` to continue the conversation;
# - when the session ends without having called `cockpit.py done <id>`, the task becomes « à relire » (review).
# CC_QUEUE_PERMISSIONS: acceptEdits (default: file edits allowed, bash allowed inside the Claude Code sandbox, anything
# else refused rather than asked) | skip (--dangerously-skip-permissions: only with the sandbox on).
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
source "$HOME/.config/claude-launcher/cc.zsh"
setopt null_glob
L="$HOME/.config/claude-launcher"; CP="$L/cockpit.py"
Q="$HOME/scratch/.queue"; mkdir -p "$Q/done" "$Q/running"
log() { print -r -- "$(date '+%F %T') $*" >> "$Q/done/queue.log" }
cfg() { python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d.get(sys.argv[2], sys.argv[3]))' "$L/config.json" "$1" "$2" 2>/dev/null || print -r -- "$2" }
MAX_RUN=$(cfg CC_QUEUE_MAX_RUN 3)
case "$(cfg CC_QUEUE_PERMISSIONS acceptEdits)" in
  skip) PFLAG=(--dangerously-skip-permissions) ;;
  *)    PFLAG=(--permission-mode "$(cfg CC_QUEUE_PERMISSIONS acceptEdits)") ;;
esac
CLAUDE_BIN=$(command -v claude) || { log "ERROR: claude not found in PATH ($PATH)"; exit 1; }
command -v tmux >/dev/null || { log "ERROR: tmux not found"; exit 1; }
is_id() { [[ "$1" =~ '^[0-9a-z]{6}$' ]] }

# 1. reap finished sessions: exit marker written, or tmux session gone
for m in "$Q"/running/*; do
  [[ "$m" == *.exit || "$m" == *.dir ]] && continue
  s="${m:t}"; tid=$(<"$m")
  if [[ -f "$m.exit" ]] || ! tmux has-session -t "=$s" 2>/dev/null; then
    code=$(cat "$m.exit" 2>/dev/null || print -r -- "?"); dir=$(cat "$m.dir" 2>/dev/null)
    is_id "$tid" && python3 "$CP" review "$tid" --note "fini (code $code), voir ${dir/#$HOME/~}" >/dev/null 2>&1
    mv "$m" "$Q/done/$s.finished"; rm -f "$m.exit" "$m.dir"
    log "finished session $s (exit $code)"
  fi
done
running=0; for m in "$Q"/running/*; do [[ "$m" == *.exit || "$m" == *.dir ]] || running=$((running+1)); done

# 2. start tasks, P1 first
for f in $(python3 "$CP" order "$Q"/*.task); do
  if (( running >= MAX_RUN )); then
    left=0; for x in "$Q"/*.task; do left=$((left+1)); done
    log "waiting: $running running (max $MAX_RUN), $left queued"; break
  fi
  text=$(<"$f"); text="${text//$'\n'/ }"
  [[ -z "$text" ]] && { mv "$f" "$Q/done/"; log "skipped empty ${f:t}"; continue; }
  tid="${${f:t}%.task}"; is_id "$tid" || tid=""
  if [[ -n "$tid" && "$(python3 "$CP" field "$tid" status)" == "done" ]]; then
    mv "$f" "$Q/done/"; log "skipped ${f:t}: already done"; continue
  fi
  if [[ -n "$tid" && "$(python3 "$CP" field "$tid" who)" == "me" ]]; then
    mv "$f" "$Q/done/"; log "skipped ${f:t}: yours to do"; continue
  fi

  # where to work: the registered project, else the scratch folder already used for this id, else a new one
  dir=""; proj=""; out="output"
  [[ -n "$tid" ]] && proj=$(python3 "$CP" field "$tid" project)
  if [[ -n "$proj" ]] && d=$(_cc_path_for "$proj" 2>/dev/null) && [[ -d "$d" && "$d" != "$CC_SCRATCH" ]]; then
    dir="$d"; out="output/$tid"
  else
    if [[ -n "$tid" ]]; then
      for lg in "$CC_SCRATCH"/*/notes/log.md; do grep -q -- "- cockpit id: $tid" "$lg" && dir="${lg:h:h}"; done
    fi
    if [[ -z "$dir" ]]; then
      n=$(python3 "$CC_NOTES_PY" slug "$text"); [[ -e "$CC_SCRATCH/$n" ]] && n="$n-$(date +%m%d-%H%M)"
      _cc_create "$n" "$text" >/dev/null || { log "FAILED create for ${f:t}"; mv "$f" "$Q/done/"; continue; }
      dir="$CC_SCRATCH/$n"
      [[ -n "$tid" ]] && print -r -- "- cockpit id: $tid" >> "$dir/notes/log.md"
    fi
  fi
  mkdir -p "$dir/notes" "$dir/$out"
  sess=$(_cc_session_name "$dir")${tid:+-$tid}
  tmux has-session -t "=$sess" 2>/dev/null && tmux kill-session -t "=$sess"

  done_cmd=""; [[ -n "$tid" ]] && done_cmd=" When it is delivered, run: python3 ~/.config/claude-launcher/cockpit.py done $tid --note \"<one line: what you produced and where>\"."
  prompt="Task from my cockpit${tid:+ (id $tid)}: ${text}

Read CLAUDE.md first and follow its rules (raw data is read-only). Do the work end to end now, without asking me anything: I am away and cannot answer. If something is missing, make the most reasonable assumption, write it at the top of your result, and carry on. Put everything you produce in ${out}/, with a short README.md there saying what is in it and what I must check or decide. Never send a message, email or post, never push, never delete. At the end: append one line to notes/log.md, and one line to the ledger as CLAUDE.md says.${done_cmd}"

  # extra folders the task may read/write (cockpit field "dirs", space-separated, ~ allowed)
  extra=(--add-dir "$HOME/.config/claude-launcher/ledger" --add-dir "$HOME/scratch/.cockpit")
  if [[ -n "$tid" ]]; then
    for x in ${(z)$(python3 "$CP" field "$tid" dirs)}; do x="${x/#\~/$HOME}"; [[ -d "$x" ]] && extra+=(--add-dir "$x"); done
  fi
  ts=$(date +%m%d-%H%M); logf="$dir/notes/run-${tid:-task}-$ts.log"
  print -r -- "$tid" > "$Q/running/$sess"; print -r -- "$dir" > "$Q/running/$sess.dir"
  # the session's own command: claude headless, then an exit marker, then a shell left open in the folder
  cmdline="${(qq)CLAUDE_BIN} -p ${(qq)prompt} ${(j: :)${(qq)PFLAG[@]}} ${(j: :)${(qq)extra[@]}} > ${(qq)logf} 2>&1; echo \$? > ${(qq)Q}/running/${(qq)sess}.exit; echo; tail -40 ${(qq)logf}; echo; echo '--- session terminée : claude -c pour continuer la conversation ---'; exec ${SHELL:-/bin/zsh} -l"
  [[ -n "$tid" ]] && python3 "$CP" start "$tid" --session "$sess" >/dev/null 2>&1   # before launch: a fast session's `done` must win
  if tmux new-session -d -s "$sess" -c "$dir" "$cmdline"; then
    running=$((running+1)); log "started session $sess in ${dir/#$HOME/~} from ${f:t}"
  else
    rm -f "$Q/running/$sess" "$Q/running/$sess.dir"; log "FAILED tmux new-session for ${f:t}"
    [[ -n "$tid" ]] && python3 "$CP" reset "$tid" >/dev/null 2>&1
  fi
  mv "$f" "$Q/done/"
done

# 3. cc commands and the inbox flag
for f in "$Q"/*.cmd; do
  cmd=$(<"$f"); cmd="${cmd//$'\n'/ }"; sess="queue-$(date +%H%M%S)"
  tmux new-session -d -s "$sess" -c "$HOME" "source ${(qq)L}/cc.zsh; cc $cmd; exec ${SHELL:-/bin/zsh} -l"
  log "ran: cc $cmd (session $sess)"; mv "$f" "$Q/done/"
done
if [[ -f "$Q/INBOX" ]]; then
  rm -f "$Q/INBOX"
  out=$(python3 "$CC_INBOX_PY" run --yes 2>>"$Q/done/queue.log")
  for t in "${(@f)out}"; do
    [[ -z "$t" ]] && continue
    id="${t%%$'\t'*}"; is_id "$id" || id="$(date +%s)-$RANDOM"
    print -r -- "${t##*$'\t'}" > "$Q/$id.task"
  done
  log "inbox processed"
fi
python3 "$CP" refresh >/dev/null 2>&1
KIT_EOF_14
mkdir -p "$T/launcher"
cat > "$T/launcher/security-settings-snippet.json" <<'KIT_EOF_15'
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch(domain:en.wikipedia.org)",
      "WebFetch(domain:fr.wikipedia.org)",
      "WebFetch(domain:www.insee.fr)",
      "WebFetch(domain:www.banque-france.fr)",
      "WebFetch(domain:www.ccomptes.fr)",
      "WebFetch(domain:www.tresor.economie.gouv.fr)",
      "WebFetch(domain:ec.europa.eu)",
      "WebFetch(domain:www.ofce.sciences-po.fr)",
      "WebFetch(domain:apnews.com)",
      "WebFetch(domain:www.reuters.com)",
      "WebFetch(domain:www.nytimes.com)",
      "WebFetch(domain:www.bls.gov)",
      "WebFetch(domain:www.census.gov)",
      "WebFetch(domain:www.nber.org)",
      "WebFetch(domain:arxiv.org)"
    ],
    "deny": [
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Read(~/.gnupg/**)",
      "Read(~/Library/Keychains/**)",
      "Read(~/Library/Cookies/**)",
      "Read(~/Library/Mail/**)",
      "Read(~/Library/Messages/**)",
      "Read(~/Library/Safari/**)",
      "Read(~/Library/Application Support/Google/Chrome/**)",
      "Read(~/Library/Group Containers/group.com.apple.notes/**)",
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/*.pem)",
      "Read(**/*.key)",
      "Edit(**/raw/**)",
      "Write(**/raw/**)",
      "Bash(rm -rf *)",
      "Bash(sudo *)",
      "Bash(git push *)"
    ]
  },
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "filesystem": {
      "denyRead": [
        "~/.ssh",
        "~/.aws",
        "~/.gnupg",
        "~/Library/Keychains",
        "~/Library/Cookies",
        "~/Library/Mail",
        "~/Library/Messages",
        "~/Library/Safari",
        "~/Library/Application Support/Google/Chrome",
        "~/Library/Group Containers/group.com.apple.notes"
      ],
      "allowWrite": [
        "~/.config/claude-launcher/ledger",
        "~/scratch/.cockpit",
        "~/scratch/.queue"
      ]
    },
    "network": {
      "allowedDomains": [
        "api.anthropic.com",
        "statsig.anthropic.com",
        "sentry.io",
        "github.com",
        "*.github.com",
        "*.githubusercontent.com",
        "pypi.org",
        "files.pythonhosted.org",
        "registry.npmjs.org"
      ]
    }
  }
}
KIT_EOF_15
mkdir -p "$T/launcher"
cat > "$T/launcher/tmux.conf" <<'KIT_EOF_16'
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
KIT_EOF_16
mkdir -p "$T/launcher"
cat > "$T/launcher/vscode_settings_snippet.json" <<'KIT_EOF_17'
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
KIT_EOF_17
mkdir -p "$T/template"
cat > "$T/template/CLAUDE.md" <<'KIT_EOF_18'
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
- **Cockpit.** If this session was started from a cockpit task (the prompt gives a cockpit id, or `notes/log.md` has a line `- cockpit id: <id>`), when the work is delivered run `python3 ~/.config/claude-launcher/cockpit.py done <id> --note "<one line>"`. Autonomous sessions put their results in the output folder named in the prompt, with a README.md saying what to check.
KIT_EOF_18
mkdir -p "$T/template"
cat > "$T/template/scratch-CLAUDE.md" <<'KIT_EOF_19'
# ~/scratch — ideas and one-off experiments

Each subfolder is one idea, created with `cc new <name>` from `.template/`.
If a session starts here at the top level, ask which subfolder (or whether to create a new one) before doing anything.

## Working rules
- Raw data is read-only; derived data goes in `data/derived/`, results in `output/`.
- Stack: Python (pandas/polars), LaTeX.
- **Ledger.** When a task is finished (a note drafted, a figure produced, an app deployed, an analysis run), append ONE line to `~/.config/claude-launcher/ledger/$(date +%G-W%V).md` in the form `- YYYY-MM-DD HH:MM | <project> | <what was done, one sentence, in French> | <links or file paths>`. Create the file if missing. This feeds the weekly memo; don't log exploration or failed attempts.
- **Cockpit.** If this session was started from a cockpit task (the prompt gives a cockpit id, or `notes/log.md` has a line `- cockpit id: <id>`), when the work is delivered run `python3 ~/.config/claude-launcher/cockpit.py done <id> --note "<one line>"`. Autonomous sessions put their results in the output folder named in the prompt, with a README.md saying what to check.
KIT_EOF_19
mkdir -p "$T/services/Accentuer.workflow/Contents"
cat > "$T/services/Accentuer.workflow/Contents/Info.plist" <<'KIT_EOF_20'
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
KIT_EOF_20
mkdir -p "$T/services/Accentuer.workflow/Contents"
cat > "$T/services/Accentuer.workflow/Contents/document.wflow" <<'KIT_EOF_21'
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
KIT_EOF_21
mkdir -p "$T/services/Launch idea.workflow/Contents"
cat > "$T/services/Launch idea.workflow/Contents/Info.plist" <<'KIT_EOF_22'
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
KIT_EOF_22
mkdir -p "$T/services/Launch idea.workflow/Contents"
cat > "$T/services/Launch idea.workflow/Contents/document.wflow" <<'KIT_EOF_23'
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
KIT_EOF_23
chmod +x "$T/install.sh"
echo "→ 24 files written; running the installer"
zsh "$T/install.sh"
