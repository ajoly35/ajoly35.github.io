#!/bin/zsh
# Research kit for Claude Code: https://ajoly35.github.io/setup.html (MIT licence).
# Writes the kit to ~/research-kit, then runs its install.sh (skips skills and agents you already have).
set -e
T="$HOME/research-kit"
mkdir -p "$T"

mkdir -p "$T/."
cat > "$T/README.md" <<'RKIT_EOF_0'
# Research kit for Claude Code

Skills and reviewer agents for research work, from https://ajoly35.github.io/setup.html
(MIT licence: take it, change it, share it). Plain text only; nothing is downloaded.

| Piece | Type | What it does |
|---|---|---|
| `lit-review` | skill | A short, verified, causal-evidence literature review in nine gated phases: kickoff questions, discovery from three sources plus adversarial searches, screening with no bulk exclusion, one batched PDF request, a per-paper evidence ledger, synthesis before prose, drafting to a word budget, review, handoff. Method in `skills/lit-review/method/` |
| `lit-review-verify` | skill | Checks that every citation supports its sentence, one subagent per paper |
| `lit-review-digest` | skill | Half a page per cited paper, for you: idea, design, data, assumptions, limits |
| `pdf-chunker` | skill | Reads long PDFs in page chunks, with page references |
| `simulate-referee` | skill | An editor and two referees read the draft before it is sent |
| `policy-analysis` | skill | Neutral, sourced fiches on a programme or reform from public sources: research agents per lot, cost, causal evidence, international comparison, number and neutrality checks |
| `fetch-sources` | skill | Downloads papers and tables through Claude in Chrome with your own access, names and logs them |
| `plan-day` | skill | Lays out a day of priorities in a "Claude plan" Google Calendar, with breaks and one colour per priority |
| `data-reviewer` | agent | Re-derives every number from the raw data and code |
| `code-reviewer` | agent | Finds bugs that change results, then reproducibility problems |
| `citation-checker` | agent | Checks each citation against the source itself |

## Install
`zsh install.sh` copies the skills to `~/.claude/skills/` and the agents to
`~/.claude/agents/`. It skips anything that already exists, so it never overwrites
your own versions. Restart Claude Code, then type `/` to see the skills.

## Use
- `/lit-review new "<question>"` in an empty project folder.
- `/policy-analysis new "<programme>"`, then `/policy-analysis lot <name>`.
- Ask for a review in plain words: "have the data-reviewer check table 2",
  "run the code-reviewer on analysis/", "citation-checker on draft/review.tex".
- Tools used by the scripts: `pdftotext`/`pdfinfo` (`brew install poppler`),
  `pdflatex` for LaTeX drafts, `pandoc` (optional).
- Optional: `~/.claude/skills/lit-review/method/style.md` holds the writing
  rules for the review; edit it to your own register.

Rules every piece follows: figures only from the source itself, never from a
press release or search snippet; nothing is sent, published or pushed without
your yes; raw data and downloaded papers are never edited.
RKIT_EOF_0

mkdir -p "$T/agents"
cat > "$T/agents/citation-checker.md" <<'RKIT_EOF_1'
---
name: citation-checker
description: Independent reviewer that checks every citation in a draft against the source itself (PDF, official page or table). Use before a draft is sent, or when asked to "check the citations" or "check the sources".
tools: Read, Grep, Glob, Bash, WebFetch
---

You check that each cited source says what the sentence says. You did not write
the draft. Never edit it.

1. Extract every sentence that carries a citation or a figure, with its line.
2. For each, open the source: the local PDF (`pdftotext`, then grep for the figure),
   the ledger row, or the official page. A press release or search snippet does
   not count as the source.
3. Verdict per sentence: supported, overstated, wrong number, wrong comparison
   group or year, not in the source, or could not open. Quote the passage or
   table cell that decides it, with the page.
4. Also check that each reference exists (DOI, NBER or SSRN number resolves to the
   same title and authors) and has not been retracted.
5. Report problems first, each with a suggested rewording.
RKIT_EOF_1

mkdir -p "$T/agents"
cat > "$T/agents/code-reviewer.md" <<'RKIT_EOF_2'
---
name: code-reviewer
description: Independent reviewer for research code (Python, R, Stata, shell). Finds bugs that change results, then reproducibility problems. Use after writing or changing analysis code, or when asked to "review the code".
tools: Read, Grep, Glob, Bash
---

You review research code you did not write. Correctness first, style last.
Never edit the code; propose changes as diffs in your report.

1. Read the code in the order it runs. Note the inputs, outputs and the claim
   each output supports.
2. Look for bugs that change results: wrong joins or filters, off-by-one in
   dates, silent type coercion, missing values dropped or filled without saying so,
   wrong clustering or weights, hard-coded numbers, results that depend on row order.
3. Run it if it is safe to (read-only, local data); compare the outputs with the
   numbers quoted in the draft.
4. Reproducibility: fixed seeds, pinned package versions, relative paths, one
   command that runs everything, raw data never overwritten.
5. Report: findings ranked by how much they could change a result, each with
   file:line, the failure scenario and a suggested fix. Then up to five minor points.
RKIT_EOF_2

mkdir -p "$T/agents"
cat > "$T/agents/data-reviewer.md" <<'RKIT_EOF_3'
---
name: data-reviewer
description: Independent reviewer for data work. Re-derives the numbers in a draft, table or chart from the raw data and the analysis code, and checks merges, units, samples and definitions. Use after any analysis, before a figure leaves the project, or when asked to "review the data".
tools: Read, Grep, Glob, Bash
---

You review someone else's data work, cold: you did not write it, and you trust
nothing until you have reproduced it. Never edit the data or the code.

1. List every number, table and chart the draft relies on, and where each comes from.
2. For each, find the raw file and the code that produced it. Re-run the code, or
   recompute the number independently with a short script of your own.
3. Check: sample restrictions and their counts at each step; merges (unmatched and
   duplicated keys); units, currency and price year; missing values and how they are
   treated; definitions against the source's documentation; weights.
4. Check that each figure in the text has the same value, year and comparison
   group as the output it comes from.
5. Report a table, most serious first: item, what you expected, what you found,
   severity (wrong / unclear / fine), file and line. End with the three checks you
   could not run and why.
RKIT_EOF_3

mkdir -p "$T/."
cat > "$T/install.sh" <<'RKIT_EOF_4'
#!/bin/zsh
# Copy the research kit into Claude Code's skills and agents folders, skipping anything already there.
set -e
here="${0:A:h}"
mkdir -p ~/.claude/skills ~/.claude/agents
for d in "$here"/skills/*(/); do
  n="${d:t}"
  if [[ -e ~/.claude/skills/$n ]]; then print "skip   skill $n (already in ~/.claude/skills)"; else cp -R "$d" ~/.claude/skills/ && print "added  skill $n"; fi
done
for f in "$here"/agents/*.md; do
  n="${f:t}"
  if [[ -e ~/.claude/agents/$n ]]; then print "skip   agent ${n:r} (already in ~/.claude/agents)"; else cp "$f" ~/.claude/agents/ && print "added  agent ${n:r}"; fi
done
chmod +x ~/.claude/skills/*/scripts/*(N) ~/.claude/skills/lit-review/method/scripts/*(N) 2>/dev/null || true
print "Done. Restart Claude Code; type / to list the skills. Tools: brew install poppler (pdftotext)."
RKIT_EOF_4

mkdir -p "$T/skills/fetch-sources"
cat > "$T/skills/fetch-sources/SKILL.md" <<'RKIT_EOF_5'
---
name: fetch-sources
description: Download the sources a project needs (papers, reports, statistical tables) through Claude in Chrome, in the user's own browser session, then name, file and log each one. Use when a ledger or reading list has sources that scripted downloads could not get, or when asked to "fetch the PDFs", "download the sources" or run /fetch-sources.
argument-hint: "[list file or ledger.csv] [--out papers/]"
---

# /fetch-sources

Needs the Claude in Chrome extension (paid Claude plans) and Google Chrome.

1. **List first.** Read the list (or the ledger rows with no local file). Try
   open-access copies by script first (`fetch_oa.sh` in the lit-review method kit,
   Crossref, OpenAlex, author pages, NBER, arXiv, institutional repositories).
2. **Then the browser, one source at a time.** For each source left, open it in
   a new tab with Claude in Chrome, use the user's existing access (library
   sign-in, subscriptions) and download the PDF or table. Never create accounts,
   enter credentials, pay, accept new terms, or solve a CAPTCHA: put that source
   on a short list for the user instead. Respect each site's terms; no bulk or
   scripted crawling of subscription sites.
3. **Name and file.** Rename each file `authors-year-short-title.pdf` (lowercase,
   hyphens), move it to the project's `papers/` folder, and record old name →
   new name, URL and date in the ledger's `local_pdf` column.
4. **Check.** Open page 1 of each file to confirm it is the right paper or table
   and the right version; extract text with `pdftotext` so figures can be grepped.
5. **Report**: downloaded, already present, and the short list the user must
   get by hand, with the link for each.

The same browser routine automates other steps that need no judgement:
downloading a statistical series, exporting a table, filling a form with known
values. Anything that sends, submits, buys or publishes still needs the user.
RKIT_EOF_5

mkdir -p "$T/skills/lit-review"
cat > "$T/skills/lit-review/SKILL.md" <<'RKIT_EOF_6'
---
name: lit-review
description: Run a short, verified, causal-evidence literature review in LaTeX using the phased playbook (kickoff, discovery with adversarial search, no-bulk screening, one batched PDF request, full-text extraction ledger, synthesis before prose, draft to budget, review, handoff). Use when the user asks to start, resume or continue a literature review.
---

# /lit-review

Method kit lives in `method/` next to this file (`~/.claude/skills/lit-review/method/`)
(`PLAYBOOK.md`, `prompts.md`, `templates/`, `scripts/`, `RETROSPECTIVE.md`).

## Arguments
- `new <topic>`: set up a new project in the current directory.
- `resume`: read `STATUS.md` + `ledger.csv`, report the phase and next step.
- `phase <n>`: run that phase of the playbook.
- `screen <pdf>`: screen one paper and its reference list.

## Instructions
1. Read `PLAYBOOK.md` in the kit. Follow its phases and gates exactly.
2. `new`: run `scripts/preflight.sh .`, then ask **all** questions in
   `templates/kickoff-questions.md` in one message with defaults filled in.
   Write the answers into `CLAUDE.md` (from the template). Do not search
   before the kickoff answers are recorded.
3. Keep `ledger.csv` as the single evidence record (schema in
   `templates/ledger-schema.md`). Never supply a figure from a press release or
   search snippet. Resolve every identifier. Run a retraction check before citing.
4. Batch every PDF request to you into one list per phase.
5. Before drafting, get your approval of the thesis and outline (Phase 5 gate).
6. Draft in the empirical literature review register of
   `~/.claude/skills/lit-review/method/style.md`: Definitions paragraph first, every
   figure with a comparison group and date, a context line per study, bulk
   citation for agreeing studies, a mechanism per key finding, no jargon.
   Build every paragraph as point, evidence, analysis (one point per
   paragraph), and open the review by defining its important terms from a
   landmark reference. Run the **reader-comprehension pass** in `PLAYBOOK.md`
   Phase 6 before the gate, then the **usefulness verifier** (Phase 7): a
   separate cold agent that deletes every sentence that adds nothing.
7. After every compile, run `scripts/check_draft.py`; delete build files.
8. Update `STATUS.md` at every gate.
9. Structure each design section around one exemplar at full detail (data,
   treatment, comparison, timing, bounded result), with the other studies of
   that design cited as a group. Redraft from your latest copy as `review-vN.tex`.
10. Handwritten comments (photos): transcribe to a new `raw-inputs/` file mapped
   to the exact text with a confidence column, give you a `.docx` with Word
   comments to approve, redraft in a new `.tex`, and ask about anything unreadable.
11. **Name every PDF in `papers/` as `authors-year-short-title.pdf`** (lowercase,
   hyphens, surnames of up to four authors, else `firstauthor-et-al`; e.g.
   `lambert-schindler-2026-broken-ladder-ai-remote-work.pdf`), so readers can see
   at a glance which paper each file is. When a PDF arrives with a download name
   (`ssrn-5516798.pdf`, `w34859.pdf`, `TheShort-term..._preview.pdf`, a title with
   spaces), read its first page, rename it, and record old → new in a new
   `raw-inputs/` file. Two versions of one paper: add the month (`2026-07`, `2026-08`).
   Keep a "not for circulation" flag in the name. Update `seed-papers.md` and
   the ledger's `local_pdf` column to the new names.

## Never
- Bulk-exclude on-topic papers that are cited by ≥2 seeds or have ≥100 citations.
- Edit, move or delete files in `papers/` (renaming to author-year, rule 11, is
  the one exception), or edit files in `raw-inputs/` in place.
- Commit, push or send anything without your explicit yes.
RKIT_EOF_6

mkdir -p "$T/skills/lit-review/method"
cat > "$T/skills/lit-review/method/PLAYBOOK.md" <<'RKIT_EOF_7'
# Literature review playbook

A transferable method for a short, verified, causal-evidence literature review
in LaTeX. Derived from the pilot review on generative AI and employment (Sep 2026); see
`RETROSPECTIVE.md` for why each rule exists.

Each phase ends with a **gate**: don't move on until it passes. Update
`STATUS.md` at every gate.

---

## Phase 0: Kickoff (one round with you, before any search)
Ask every question in `templates/kickoff-questions.md` in **one** message.
Record the answers in the project `CLAUDE.md` (from `templates/CLAUDE.md.template`).

Preflight (run `scripts/preflight.sh`):
- `pdflatex`, `bibtex`, `pdftotext`, `pandoc`, `python3` + `fitz` available.
- Folder skeleton: `papers/` (read-only except author-year renames), `raw-inputs/`, `draft/`, `ledger.csv`, `STATUS.md`.

**Gate:** kickoff answers recorded; preflight passes; word budget set
(about 620 words per page at 11pt, 1in margins, 2pt paragraph skip, compact section headings (measured: 1,879 words filled 3 pages in the pilot review)).

## Phase 1: Discovery (three independent sources)
1. **Seeds**: build `seed-papers.md` (ID, file, title, authors, date, link).
2. **Backward citations**: extract each seed's bibliography (`pdftotext`),
   filter on topic, dedupe, and count how many seeds cite each item.
3. **Forward citations**: OpenAlex (primary) and Semantic Scholar, restricted to
   the date floor. Record which seeds are not yet indexed.
4. **Deep-research pass**: `/deep-research` on the question, with the evidence standard in the prompt.
5. **Adversarial queries** (run now, not later): "[main finding] null",
   "[main finding] confound", "[main finding] critique", "[leading outcome]
   [alternative explanation]", plus replications in other countries.

Every hit goes into `ledger.csv` with `status=found`.

**Gate:** ledger contains all three sources; the adversarial queries are logged.

Practitioner syntheses (Substack reviews, trackers, talks) are leads: mine their reference lists and trace every figure to the paper itself.

## Phase 2: Screening (no bulk exclusion)
Rules, in order:
1. Off-topic, pre-floor, or wrong technology → `status=out` with a reason (bulk allowed **only** for these).
2. On-topic and (cited by ≥2 seeds **or** ≥100 citations **or** from the adversarial pass) →
   **must** be individually resolved: verified or rejected with a reason.
3. Everything else on-topic → tiered A/B/C with a one-line reason.

Resolve identifiers: open every SSRN/NBER/DOI and confirm title + authors
match. Seed bibliographies contain miscitations (S2 cited a paper that does not exist).

**Gate:** zero on-topic rows with `status=found`; Tier A list drawn up.

## Phase 3: Access (one batched request)
- Try open copies first: NBER, arXiv, IZA, Census, central banks, authors' sites,
  university repositories (`scripts/fetch_oa.sh`).
- Metadata fallback: Crossref API, PubMed E-utilities.
- **Everything else goes in one list to you** (links + target filenames). SSRN returns
  403 to fetches, so every SSRN-only paper goes on this list.
- **Rename on arrival**: every PDF that lands with a download name (`ssrn-NNNNNNN.pdf`,
  `wNNNNN.pdf`, a title with spaces) is renamed `authors-year-short-title.pdf` from its
  first page, so a co-author can browse `papers/`. Log old → new in a new `raw-inputs/` file.

**Gate:** every Tier A paper has a local PDF or an official abstract, or is marked
`unverifiable` (and dropped).

## Phase 4: Extraction (card per paper, from full text only)
Read papers over 20 pages with `/pdf-chunker`, so every figure carries a page reference.
Fill the ledger columns for each Tier A paper (see `templates/ledger-schema.md`):
data, country, period, design, treatment measure, exposure index, outcome
type (stock / flow / wage / postings / productivity), headline figures **with
page or line reference**, heterogeneity splits, controls for known confounds,
data provider, version date, retraction check. Also record, for the reader:
the **setting in one line** (who, where, what task), the **comparison group
and reference date** behind each headline figure, how skill/experience groups
are **defined**, how the treatment measure is **built** (with a concrete
example, e.g. the actual keywords), and the **mechanism** the authors give.
For one **exemplar per design**, record five elements: data and sample,
treatment definition, comparison group, timing and base period, result with
its bound or baseline. For preliminary or do-not-circulate papers, record
whether you have permission to cite.

Rules:
- Figures come only from the paper itself. Press releases and search summaries
  are leads; they never supply a figure.
- If the working paper and published versions differ, use the published version and note both.
- Retraction check for every paper cited.

**Gate:** every row that will be cited has figures with a page reference and `retraction_checked=yes`.

## Phase 5: Synthesis before prose
From the ledger, build (in `raw-inputs/synthesis.md`):
- An evidence table sorted by design → the section skeleton.
- A **disagreement map**: results that conflict, and the candidate explanations
  (outcome type, country, confound, firm selection, timing).
- A shared-data check (count papers per provider).
- A thesis stated in 2 sentences, including what is *not* settled.
- A **definitions list**: every constructed measure the draft will use
  (e.g. exposure, substitutability, adoption), each in one plain sentence
  with its source. It becomes the "Definitions" paragraph in the introduction.
- For each section, the **question** it answers (sections with mixed evidence
  open with that question).

**Gate:** you approve the thesis and section outline (one short round).

## Phase 6: Draft to budget
- Write to the word budget from Phase 0, in the style from Phase 0.
- Every `\cite` must match a ledger row with `status=verified`.
- Compile and run `scripts/check_draft.py` (page of the References heading,
  body word count, banned characters such as hyphens, undefined citations, BibTeX warnings).
- Start every redraft from your latest copy (`/overleaf pull`, or the Overleaf download), note what was removed, and save as a new `review-vN.tex`.
- Each design section: one sentence on what the design compares, the exemplar with its five elements, then the other studies of that design cited as a group with a one-line design each.
- Write in the empirical literature review register of
  `~/.claude/skills/lit-review/method/style.md`.
- Budget about 10% of the words for definitions and context lines; don't
  spend it on study-by-study detail for results many papers agree on.

### Reader-comprehension pass (before the gate)
From the author's comments on the pilot review. Go sentence by sentence; each check is pass/fail:
1. **Definitions first**: the review opens by defining its important terms, starting from a landmark study or reference that sets the question, before any result uses them.
2. **First-use terms**: every technical term (task model, chain of tasks, callback, instrument, synthetic DiD) gets one plain clause.
3. **Reference point**: every %, pp or SD states the comparison group and the date/period. Target 0 figures without both.
4. **Context line**: every cited result has setting, country and sample (or task) in the same or previous sentence.
5. **Plain meaning**: every estimate is stated as what it means for the people or units studied; every data source is spelled out and glossed; method verbs say what the authors did.
6. **Bulk citation**: where 3+ studies agree, one sentence with grouped citations ("one side shows X, the other Y"), then only the study that adds something.
7. **Mechanism**: each key finding has one clause on why or what follows.
8. **Placement**: heterogeneity points in the heterogeneity section; definitions in Definitions; debate-framing findings in the introduction.
9. **Scope**: side outcomes (e.g. productivity in an employment review) get at most one paragraph, tied to the main outcome.
10. **Magnitude**: headline numbers say whether they are big, against a baseline.
11. **Parameters named**: a section whose studies vary a dimension (a treatment, its intensity, a unit's size) names those parameters in its first sentence, then gives one question-led paragraph per parameter.
12. **Point, evidence, analysis** (the foundation): one point per paragraph; each opens with a one-sentence claim, gives the evidence, and ends with the causal chain from parameter to the review's outcome (split by its key subgroups where possible) plus the main caveat.

**Gate:** compiles cleanly; body within the page limit; style check passes; reader-comprehension pass has 0 fails.

## Phase 7: Review loop
- A fresh-eyes pass (`/review-plan` or a subagent) checks: every figure is in the
  ledger; the thesis matches the disagreement map; nothing canonical is missing
  (compare against the reference lists of the two most-cited seeds).
- Rerun the reader-comprehension pass as a cold reader (a subagent that has
  not seen the papers): list every sentence where it would ask "what does
  that mean?" or "compared to what?".
- **Citation check**: `/lit-review-verify` on the draft; fix every mismatch before sending.
- **Reader simulation**: `/simulate-referee` with the commissioning brief, before the draft goes to the commissioner.
- **Usefulness pass**: a separate verifier agent, cold, reads every sentence
  and asks "Is this sentence truly useful to the review? Does it add
  anything?" It deletes sentences (and clauses) that add nothing, never adds
  content, keeps each paragraph's point and analysis and anything you asked for (pass it that list), and writes a log
  (deleted text, why) to a new `raw-inputs/` file. Prompt in `prompts.md` §7.
  Run it after every redraft, before sending you a version.
- When you comment on paper (photos of handwritten notes): transcribe
  into a new `raw-inputs/` file with an anchor-to-text mapping and a
  confidence column, and give the author a `.docx` with each note as a Word comment
  (tracked deletions for the author's strike-throughs) to approve.
- Record changes in the ledger, not in new addenda files.

**Gate:** open items listed in `STATUS.md`; nothing unverified in the draft.

## Phase 8: Handoff
- Optional, for you only: `/lit-review-digest` writes `digest/paper-digests.md`, half a page per cited paper (core idea, methodology, empirical strategy, data, assumptions, limitations, policy implications). Run it after Phase 4, when the ledger has page references.
- `STATUS.md`: what's done, open items, decisions taken, file map.
- Delete build files (`.aux .bbl .blg .log .out`).
- Daily update / email draft if relevant.
RKIT_EOF_7

mkdir -p "$T/skills/lit-review/method"
cat > "$T/skills/lit-review/method/RETROSPECTIVE.md" <<'RKIT_EOF_8'
# Retrospective: pilot review on generative AI and employment (23–24 Sep 2026)

How the back-and-forth could have been faster and deeper. Each lesson maps
to a rule in `PLAYBOOK.md`.

## Timeline as it happened
| # | Round | What it cost |
|---|---|---|
| 1 | Seeds → backward/forward citation mining → deep-research pass → `candidates.md` (14 core) | Fine, but screening dropped about 160 papers in bulk as "not individually verified" |
| 2 | Draft written; **no LaTeX installed**; user had to run `brew install` | 1 blocked round |
| 3 | Compiled at 4 pages → 5 trimming passes | About 200 words cut by trial and error |
| 4 | "Resume": no handoff file, so state was rebuilt from transcripts | 3 tool calls of archaeology |
| 5 | Corrections file + unverified-figure list | Should have existed from round 1 |
| 6 | User supplied 2 PDFs → **Klein Teeselink figures wrong** (taken from a KCL press release, not the paper) | Error had already reached the draft |
| 7 | User pasted an S2 passage → **Noy & Zhang and Dell'Acqua missing**, the two most-cited GenAI experiments | Caused by the bulk exclusion in round 1 |
| 8 | Built the unverified list (27 Tier A) → link search → 6 PDFs requested | 2nd download round for the user |
| 9 | Verified 16 papers; **Lambert & Schindler** (WFH confound) and **Nordic nulls** forced a reframe; S2 miscitation settled | Thesis rewritten late |
| 10 | User asked whether methods (Hampole method, Eloundou measure, AEI) were covered → no | Depth gap in per-paper extraction |
| 11 | Style: remove "Maasoum", remove all hyphens, more fluid prose → full rewrite + 2 trim passes | Style rules arrived after drafting |
| 12 | Extra paper (Aghion et al.) → reference screen; **Toner-Rodgers found to be disavowed by MIT** | No retraction check existed |

## Efficiency: what to change
| Problem | Root cause | Fix (playbook rule) |
|---|---|---|
| Blocked on LaTeX | Toolchain not checked at start | **Phase 0 preflight**: `pdflatex`, `bibtex`, `pdftotext`, `pandoc` present before any drafting |
| 3 separate "please download" rounds | Paywalled/SSRN papers found piecemeal | **One batched PDF request** after screening, listing every blocked link at once (SSRN returns 403 to fetches, so assume every SSRN paper needs one) |
| 5 trim passes for the page limit | Drafted without a word budget; reference policy decided late | Set a **word budget** in Phase 0 (here: about 1,850 body words = 3 pages at 11pt, 1in margins (measured)) and decide whether references count toward the limit |
| Full rewrite for style | Style rules (hyphens, name forms, register) given after drafting | **Kickoff questions** include style: dashes/hyphens, author-name form, first person, British/US spelling |
| Evidence-standard decisions mid-stream | "Is an Anthropic report OK?", "can references spill?" | Kickoff checklist asks these before the search |
| "Resume" required transcript digging | No state file | `STATUS.md` updated at the end of every phase |
| 6 files in `raw-inputs/` (corrections, addenda, logs) | "Never edit in place" + no single ledger | **One append-only evidence ledger** (`ledger.csv`) with a status column; notes files only for narrative |

## Depth: what to change
| Problem | Root cause | Fix |
|---|---|---|
| Canonical papers dropped | Bulk exclusion of anything not verified in one pass | **No bulk exclusion of on-topic items.** Any paper that is cited by ≥2 seeds, or has ≥100 citations, and passes the topic filter must be individually verified or explicitly rejected |
| Wrong figures from a press release | Snippet/press numbers accepted as "verified" | **Figures only from the paper's own text** (PDF or official abstract). Press releases and search summaries = leads, never sources |
| Contradicting evidence found late | No adversarial search step | **Phase 1 adversarial queries**, run with discovery and well *before drafting*: search for nulls, confounds, critiques and replications of the leading result (here, "remote work", "monetary policy", "pre-trends") |
| Methods not described (how adoption/exposure measured) | Extraction captured results, not design | **Per-paper extraction card**: data, treatment measure, exposure index, identification, controls for known confounds, outcome type (stock vs flow), provider |
| S2 cited a non-existent Azar/Gaggl/Taska paper | Citations taken from bibliographies at face value | **Resolve every identifier** (SSRN/NBER/DOI) to the actual title/authors on the live page |
| Disavowed paper in a seed's reference list | No retraction check | **Retraction check** (Retraction Watch, publisher/institution statements) for every cited paper |
| Disparities surfaced by hand | No structured evidence table | Ledger columns (country, outcome type, WFH control, provider) make disagreements and shared-data dependence visible early |
| Data dependence (6 papers on Revelio) noticed late | Provider not recorded | `provider` column in ledger |
| Open item still unresolved: which exposure studies control for WFH | Not in extraction card | Confound-control column, filled for every paper |

## What worked and should be kept
- Seed PDFs → backward + forward citation mining → deep-research pass as a third source.
- The hard evidence rule ("verify against a live source or drop").
- Checking PDFs locally with `pdftotext` + `grep` for exact figures. It is fast and settles disputes.
- Crossref/PubMed APIs for metadata when publisher pages 403 (Noy & Zhang via PubMed).
- Backing up the draft to scratch before each rewrite.
- Organising the draft by method plus a cross-cutting heterogeneity section, plus a
  "why the results disagree" section. The last was the most valuable addition.

## Round 2: the author's handwritten comments
About 60 comments on pages 1 and 2 of the draft. They were overwhelmingly about
**reader comprehension**, not accuracy: no figure was challenged as wrong. The
draft was correct but written for someone who had already read the papers.

| What the reader asked | How often (approx.) | Root cause | Fix |
|---|---|---|---|
| "Define", "what is it?" (exposure, firm exposure, substitutable, OEWS, CPS, SD gap, task model, chain of tasks, callback) | 15+ | Measures used before, or never, defined; the exposure definition sat in the macro section | Definitions list in Phase 5; Definitions paragraph in the introduction; first-use clause rule |
| "Compared to what / when?", "is that big?" | 8 | Figures copied from the ledger without their comparison group | Ledger records comparison group and reference date; reader-comprehension check 3 and 10 |
| "No context", "what quality?", "of what?", "which gap?" | 8 | Results stated without setting, task or outcome definition | Context line per study in Phase 4 and check 4 |
| "Rephrase" jargon ("imprecise zero", "rule out", p-values) | 6 | Paper-internal language reused | Jargon ban, check 5 |
| "Cite in bulk", "one sentence + collapse citations", "too much on productivity" | 4 | Study-by-study walk-through of results that agree; side outcome over-weighted | Bulk-citation and scope checks 6 and 9 |
| "Change word 'identify'", "more specific: GenAI keywords, example needed" | 3 | Methods described abstractly | Record how each measure is built, with an example |
| "Consequence skipped", "what explains this shift?" | 3 | Estimates without mechanism | Mechanism clause, check 7 |
| "Move to intro", "should be up to section 4", "fits elsewhere" | 4 | Sentences placed by source paper, not by argument | Placement check 8 |
| "Frame as a question" | 2 | Mixed evidence presented as a list | Sections with mixed evidence open with the question they answer |

Also kept: transcribing photos into a mapped `raw-inputs/` file plus a Word file
with comments the author can approve worked as a review loop. The rules now live in
`method/style.md` and
the Phase 6 reader-comprehension pass.

## 2026-09-30: from first draft to v33
- The supervisor's brief (3 pages, by method, micro first) arrived late and forced a restructure. Kickoff now asks for the brief verbatim (question 0).
- The format that worked: one exemplar per design at full detail (the Humlum & Vestergaard paragraph set the standard), the rest cited as a group.
- Practitioner reviews (Imas & Schaal; Berger; the McCrory talk) were efficient discovery tools once every figure was traced to the paper; AI overviews got definitions wrong (Eloundou's measures, "quality").
- Editing drifted between Overleaf and local files; redrafts now start from your latest copy.
- The usefulness verifier cut content the author had explicitly asked for; it now receives that list.
RKIT_EOF_8

mkdir -p "$T/skills/lit-review/method"
cat > "$T/skills/lit-review/method/prompts.md" <<'RKIT_EOF_9'
# Copy-paste prompts, one per phase

Replace `{{...}}`. Each prompt assumes the project was set up with
`scripts/preflight.sh` and that `CLAUDE.md` is filled in.

---

## 0. Kickoff
> I want a literature review on {{QUESTION}}. Seed PDFs are in `papers/`.
> Follow `method/PLAYBOOK.md`. Start with Phase 0: run preflight, then ask me
> every kickoff question in `method/templates/kickoff-questions.md` in one
> message, with your suggested defaults filled in.

## 1. Discovery
> Phase 1. Build `seed-papers.md`, then mine backward citations (every seed's
> bibliography) and forward citations (OpenAlex, then Semantic Scholar), and run
> `/deep-research` with the evidence standard from `CLAUDE.md`. Also run the
> adversarial queries: nulls, confounds, critiques and replications of the
> leading finding. Put every hit in `ledger.csv` as `found`. Report counts per source.

## 2. Screening
> Phase 2. Screen `ledger.csv`. Bulk exclusion is allowed only for off-topic,
> pre-{{YEAR}} or wrong-technology rows. Anything on-topic that is cited by ≥2
> seeds, has ≥100 citations, or came from the adversarial pass must be
> resolved individually. Resolve every SSRN/NBER/DOI to its live title and
> authors, and flag any mismatch with how the seeds cite it. Output the Tier A list.

## 3. Access
> Phase 3. For every Tier A paper, try open copies with
> `method/scripts/fetch_oa.sh`, and use Crossref/PubMed for metadata. Then
> give me **one** list of everything I need to download (link and target
> filename), SSRN included.

## 4. Extraction
> Phase 4. The PDFs are in `papers/`. Fill every ledger column for each Tier A
> paper from the full text only, with a page reference for each figure,
> including treatment/exposure measure, outcome type, controls for
> {{KNOWN CONFOUNDS, e.g. remote work, monetary policy}}, and data provider.
> Run a retraction check on each. List any figure that differs from what the
> seeds or press coverage report.

## 5. Synthesis
> Phase 5. From the ledger, write `raw-inputs/synthesis.md`: evidence table by
> design, disagreement map with candidate explanations, papers per data
> provider, a two-sentence thesis that says what is not settled, a
> definitions list (every constructed measure, one plain sentence each) and
> the question each section answers. Stop for my approval of the thesis and outline.

## 6. Draft
> Phase 6. Draft `draft/review.tex` and `references.bib` to the word budget and
> style in `CLAUDE.md` and the empirical literature review register in
> `~/.claude/skills/lit-review/method/style.md`. Open with a Definitions paragraph.
> Per design: what it compares, one exemplar with data, treatment,
> comparison, timing and bounded result, then the rest cited as a group.
> Give every figure a comparison group and date, every study a one-line
> context (who, where, what task), and every key finding its mechanism. Cite
> agreeing studies in bulk. No jargon ("imprecise zero", "rule out", bare
> p-values, unglossed acronyms). Cite only `verified` ledger rows. Run
> `python3 method/scripts/check_draft.py draft --pages {{N}} --no-hyphens --allow GPT-4`
> and the reader-comprehension pass in `PLAYBOOK.md`, and iterate until both pass.

## 7. Review
> Phase 7. Fresh-eyes review: check every figure in the draft against the
> ledger; check that the thesis matches the disagreement map; compare the
> reference lists of the two most-cited seeds against the draft for anything
> canonical that is missing; check the methods of each key paper are described
> (how treatment is measured). Report gaps before editing.

### 7b. Usefulness verifier (separate, cold agent)
> Read `draft/review.tex`. For every sentence in the body, ask: "Is this
> sentence truly useful to the review? Does it add anything?" A sentence
> adds something if it makes the paragraph's point, gives evidence with the
> context it needs, gives analysis (causal chain or a caveat that changes
> interpretation), or defines a term used later. Delete sentences and
> clauses that add nothing; add nothing yourself; keep each paragraph's
> point and analysis. Write the edited copy to a new versioned file and a
> log (section, deleted text, why) to a new `raw-inputs/` file; list any
> study that lost its only citation. Then run `scripts/check_draft.py`.

## 8. Handoff
> Phase 8. Update `STATUS.md` (numbers, decisions, open items, waiting-on-me),
> delete build files, and draft my daily update if relevant.

---

## Ad hoc
- **User adds a paper:** "Screen `papers/{{file}}` and every item in its reference
  list against `CLAUDE.md`: cite the paper or not, and which references (if any)
  qualify. Run a retraction check. Add rows to the ledger."
- **Handwritten comments:** "My comments on the draft are photos in
  `raw-inputs/{{files}}`. Transcribe them into a new file mapped to the exact
  text (with a confidence column), build a `.docx` with each as a Word comment
  and my strike-throughs as tracked deletions, start the redraft in a new
  `.tex`, and list anything you can't read or interpret."
- **Resume:** "Read `STATUS.md` and `ledger.csv` and tell me where we are and the next step."
- **New source from a blog or talk:** "Here is {{link}}. List the studies it cites that we don't, check each against the paper itself, and suggest where each fits by design, micro studies first."
- **Final check before sending:** "My latest version is {{path}}. Compile it, run `/lit-review-verify` and `/simulate-referee` with the brief, flag errors and repetition, fix them in a new `review-vN.tex`, and draft the covering email."
RKIT_EOF_9

mkdir -p "$T/skills/lit-review/method/scripts"
cat > "$T/skills/lit-review/method/scripts/check_draft.py" <<'RKIT_EOF_10'
#!/usr/bin/env python3
"""Phase 6 draft check: compile, then report page fit, word count, style violations.

Usage: python3 check_draft.py DRAFT_DIR [--pages 3] [--no-hyphens] [--keep-build]
                                        [--allow GPT-4 --allow ...] [--banned-words delve,leverage]

Checks:
  - compiles (pdflatex, bibtex, pdflatex x2); undefined citations; BibTeX warnings
  - page of the References heading, and whether the body ends within --pages
  - body word count (text before the References heading)
  - hyphens/dashes in the body (excluding \\cite keys and --allow tokens)
  - banned words
Deletes build files unless --keep-build.
"""
import argparse, os, re, subprocess, sys

p = argparse.ArgumentParser()
p.add_argument("draft_dir")
p.add_argument("--tex", default="review.tex")
p.add_argument("--pages", type=int, default=3)
p.add_argument("--no-hyphens", action="store_true")
p.add_argument("--allow", action="append", default=[])
p.add_argument("--banned-words", default="delve,leverage,multifaceted,furthermore,moreover,robust,compelling,navigate,foster,transformative,pivotal")
p.add_argument("--keep-build", action="store_true")
a = p.parse_args()

os.chdir(a.draft_dir)
base = a.tex[:-4]
run = lambda cmd: subprocess.run(cmd, capture_output=True, text=True)
run(["pdflatex", "-interaction=nonstopmode", a.tex])
bib = run(["bibtex", base])
run(["pdflatex", "-interaction=nonstopmode", a.tex])
last = run(["pdflatex", "-interaction=nonstopmode", a.tex])
problems = []

log = last.stdout
if "undefined" in log.lower():
    problems.append("undefined references/citations in log")
if re.search(r"^! ", log, re.M):
    problems.append("LaTeX errors in log")
warn = re.findall(r"^Warning--.*$", bib.stdout, re.M)
if warn:
    problems.append(f"{len(warn)} BibTeX warnings: " + "; ".join(warn[:3]))

import fitz
doc = fitz.open(base + ".pdf")
ref_page = None
for i, page in enumerate(doc):
    if page.search_for("References"):
        ref_page = i + 1
        y = page.search_for("References")[0].y0
text = "".join(pg.get_text() for pg in doc)
body = text[: text.find("References")] if "References" in text else text
words = len(body.split())
p4 = doc[a.pages].get_text().strip() if doc.page_count > a.pages else ""
body_fits = ref_page is not None and (ref_page <= a.pages or p4.startswith("References"))
print(f"pages: {doc.page_count} | References heading: page {ref_page} (y={y:.0f}) | body words: {words}")
if not body_fits:
    problems.append(f"body runs past page {a.pages}")

src = open(a.tex).read()
start = src.find("\\section{", src.find("\\begin{document}"))
end = src.find("\\bibliographystyle")
b = re.sub(r"\\(cite[pt]?|ref|label|vspace|hspace)\{[^}]*\}", "", src[start:end])
if a.no_hyphens:
    hy = [t for t in re.findall(r"\S*(?:-|\u2013|\u2014)\S*", b) if t not in a.allow]
    if hy:
        problems.append(f"{len(hy)} hyphen/dash tokens: {sorted(set(hy))[:15]}")
banned = [w for w in a.banned_words.split(",") if w and re.search(rf"\b{w}\b", b, re.I)]
if banned:
    problems.append(f"banned words: {banned}")

if not a.keep_build:
    for ext in (".aux", ".bbl", ".blg", ".log", ".out"):
        try: os.remove(base + ext)
        except FileNotFoundError: pass

print("PASS" if not problems else "FAIL\n  - " + "\n  - ".join(problems))
sys.exit(1 if problems else 0)
RKIT_EOF_10

mkdir -p "$T/skills/lit-review/method/scripts"
cat > "$T/skills/lit-review/method/scripts/fetch_oa.sh" <<'RKIT_EOF_11'
#!/usr/bin/env bash
# Phase 3: download open-access PDFs and extract text for grep-based verification.
# Usage: bash fetch_oa.sh OUT_DIR name1 url1 [name2 url2 ...]
# Prints type + page count for each file; anything that is not a PDF needs another
# source (try an author/repository copy) or goes on the batched request to you.
# SSRN returns 403 to scripted fetches, so don't bother; list those for you.
set -u
out="$1"; shift
mkdir -p "$out"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 Chrome/126 Safari/537.36"
while [ $# -ge 2 ]; do
  name="$1"; url="$2"; shift 2
  curl -sL -A "$UA" --max-time 60 -o "$out/$name.pdf" "$url"
  kind="$(file -b "$out/$name.pdf" | cut -c1-24)"
  pages="$(pdfinfo "$out/$name.pdf" 2>/dev/null | awk '/^Pages/{print $2}')"
  if [ -n "$pages" ]; then
    pdftotext -layout "$out/$name.pdf" "$out/$name.txt" 2>/dev/null
    printf "ok     %-14s %3s pages\n" "$name" "$pages"
  else
    printf "FAILED %-14s (%s) %s\n" "$name" "$kind" "$url"
  fi
done
# Metadata fallbacks when a publisher page is blocked:
#   curl -s "https://api.crossref.org/works/<DOI>"
#   curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=<DOI>[doi]"
#   curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=<PMID>&rettype=abstract&retmode=text"
RKIT_EOF_11

mkdir -p "$T/skills/lit-review/method/scripts"
cat > "$T/skills/lit-review/method/scripts/preflight.sh" <<'RKIT_EOF_12'
#!/usr/bin/env bash
# Phase 0 preflight: toolchain + folder skeleton for a literature review project.
# Usage: bash method/scripts/preflight.sh [project_dir]
set -u
dir="${1:-.}"
ok=1
for t in pdflatex bibtex pdftotext pdfinfo pandoc python3 curl; do
  if command -v "$t" >/dev/null 2>&1; then echo "ok      $t"; else echo "MISSING $t"; ok=0; fi
done
python3 -c "import fitz" 2>/dev/null && echo "ok      python fitz (PyMuPDF)" || { echo "MISSING python fitz (pip install pymupdf)"; ok=0; }
[ "$ok" = 1 ] || echo ">> Missing tools: pdflatex/bibtex via 'brew install --cask basictex' (needs sudo, so run it yourself with the ! prefix), poppler via 'brew install poppler'."

mkdir -p "$dir/papers" "$dir/raw-inputs" "$dir/draft"
here="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$dir/ledger.csv" ] || cp "$here/templates/ledger.csv" "$dir/ledger.csv"
[ -f "$dir/STATUS.md" ] || cp "$here/templates/STATUS.md.template" "$dir/STATUS.md"
[ -f "$dir/CLAUDE.md" ] || cp "$here/templates/CLAUDE.md.template" "$dir/CLAUDE.md"
echo "skeleton ready in $dir"
RKIT_EOF_12

mkdir -p "$T/skills/lit-review/method"
cat > "$T/skills/lit-review/method/style.md" <<'RKIT_EOF_13'
# Style: empirical literature review register

Distilled from about 60 handwritten comments on a pilot review. These are **reader
comprehension** rules. The reader's recurring question was "what does that mean?",
not "is that right?". Write for a smart economist who has not read the
papers.

## Foundation: point, evidence, analysis
Every paragraph is built the same way, with **one point per paragraph**:
1. **Point**: the claim, in one sentence, first.
2. **Evidence**: the studies that support it, each with its context
   (sample, country, setting, what was compared) and a reference point
   for every number (compared to what group, since when).
3. **Analysis**: what the evidence means: the causal chain from the
   parameter to the review's outcome, split by the review's key
   subgroups where possible, and the main caveat (selection, pre-trends).

## Facts first, then the explanation
Each point opens with what the data show (aggregate indicators,
high-frequency data, preliminary evidence), stated as the point. The
paragraph then digs into the specific reasons: the theory and the causal
studies that explain that fact. The conclusion follows the facts and is
revised when they change.

## Open by defining the terms of the question
- The review starts by defining its important terms (the constructed
  measures and concepts every later section relies on), before any
  result that uses them.
- Each reflection starts from a landmark study or reference that sets
  the question; the question's terms are defined before the review sets
  out to answer it.
- Sections whose studies vary a dimension (a treatment, its intensity, a
  unit's size) name those parameters in the opening sentence, then give
  one question-led paragraph per parameter ("How does X affect the
  outcome?").

## Making each point readable
- **Plain meaning for every term and number.** A technical term gets one
  plain clause at first use; a data source is spelled out and glossed
  ("the Current Population Survey, a monthly household survey"); an
  estimate is stated as what it means for the people or units studied
  ("not significant, and the confidence interval is wide").
- **Magnitude.** Headline numbers come with a baseline or benchmark so
  the reader can judge whether they are big.
- **Concrete measures.** Show how a measure is built, with an example,
  and use verbs that say what the authors actually did.
- **Defined groups.** When a result splits by skill, experience or age,
  say how the study defined each group.
- **Bulk citation for agreement.** Where many studies agree, one sentence
  with grouped citations ("one side of the literature shows X (a; b; c),
  the other shows Y (d; e)"), then detail only the study that adds
  something.
- **Paper first.** Evidence sentences open with the study ("Author
  (year) find...").
- **Critiques as comparisons.** Say which designs a critique hits hardest
  and which less, and why their measurement differs.
- **Right place.** Heterogeneity points go in the heterogeneity section,
  definitions at the start, debate-framing findings in the introduction;
  side outcomes get one short paragraph tied back to the main outcome.
- **Conclusions consistent with all the evidence.** A closing claim about
  one subgroup is checked against the results for every other subgroup
  in the review.

## Usefulness check
After drafting, a separate verifier agent reads the review sentence by
sentence and asks: "Is this sentence truly useful to the review? Does it
add anything?" Sentences that add nothing are deleted. See the
usefulness pass in the lit-review playbook (Phase 7).

<example>
<context>pilot review, exposure-designs section. Before = first
draft as marked up; after = redraft addressing the comments</context>
<example_text>
Before: In Norway, the relative decline for young workers in the most
exposed occupations is an imprecise zero (Hernaes and Kostol, 2026).

After: In Norway, young workers in the most exposed fifth of occupations
show no significant relative decline, although the confidence interval is
wide (Hernaes and Kostol, 2026).

Before: In Sweden, employment of 22 to 25 year olds in exposed occupations
was 5.5% lower by early 2025.

After: In Sweden, within the same employers, employment of 22 to 25 year
olds in highly exposed occupations was 5.5% lower by early 2025 than in
less exposed ones.
</example_text>
<notes>
Jargon replaced by its meaning; the comparison group and the reference
date are both stated. Same length, far easier to follow.
</notes>
</example>
RKIT_EOF_13

mkdir -p "$T/skills/lit-review/method/templates"
cat > "$T/skills/lit-review/method/templates/CLAUDE.md.template" <<'RKIT_EOF_14'
# CLAUDE.md: {{TOPIC}} literature review

Method: follow `method/PLAYBOOK.md` (copied from the lit-review skill).
State: `STATUS.md`. Evidence: `ledger.csv` (single source of truth).

## Goal
A literature review of **at most {{N}} pages of body text** on {{QUESTION}}
(outcomes: {{OUTCOMES}}), with heterogeneity by {{DIMENSIONS}}.
References {{may / may not}} run past page {{N}}.

## Structure
Organised **by methodology**:
- {{method bucket 1}}
- {{method bucket 2}}
- {{...}}
Brief: {{exposure / macro / theory}}.
Cross-cutting sections: **heterogeneity by {{DIMENSIONS}}**, and **why the results disagree**.

## Evidence standard
- {{Causal only}}, **{{YEAR}} onwards**, {{technology definition}}.
- Accepted sources: {{NBER, SSRN, arXiv, IZA, journals, ...}}.
- Benchmarks outside scope: {{allowed, ≤2, labelled}}. Descriptive counterpoints: {{allowed if labelled / not allowed}}.
- **Figures only from the paper's own text** (PDF or official abstract). Press
  releases and search snippets are leads, never sources.
- Every identifier (SSRN/NBER/DOI) resolved to its live title and authors.
- Retraction check for every cited paper.
- No citation enters `references.bib` unless its ledger row is `verified`.

## Style
- Register: {{academic, first person, claims first}}; spelling: {{British}}.
- Hyphens/dashes in body text: {{none (compounds rewritten, ranges as "x to y")}}.
- Author names: {{short form}}.
- Word budget: about {{620 × N}} body words (measured at 11pt, 1in, compact headings).
- Reader: {{a smart economist who has not read these papers}}. Follow the empirical
  literature review register in `~/.claude/skills/lit-review/method/style.md` and pass the
  reader-comprehension checks in `method/PLAYBOOK.md` Phase 6 (definitions first,
  every figure with a comparison group and date, a context line per study).

## Output
- LaTeX `draft/review.tex`, `draft/references.bib` (natbib authoryear, {{11pt, 1in}}).
- Must compile cleanly; `method/scripts/check_draft.py` must pass.
- Delete build files after each compile.

## Folder roles
| Folder | Role |
|---|---|
| `papers/` | PDFs. **Read-only**: never edit, rename, move or delete. |
| `raw-inputs/` | Deep-research reports, citation mining, synthesis. Never edit in place; add new files. |
| `ledger.csv` | Append/update rows only; never delete. |
| `draft/` | `review.tex`, `references.bib`, `review.pdf`. |
RKIT_EOF_14

mkdir -p "$T/skills/lit-review/method/templates"
cat > "$T/skills/lit-review/method/templates/STATUS.md.template" <<'RKIT_EOF_15'
# STATUS: {{TOPIC}} literature review

_Last updated: {{YYYY-MM-DD HH:MM}} by Claude_

## Phase
{{0 Kickoff | 1 Discovery | 2 Screening | 3 Access | 4 Extraction | 5 Synthesis | 6 Draft | 7 Review | 8 Handoff}}. Gate passed: {{yes/no}}

## Numbers
| Item | Count |
|---|---|
| Ledger rows | |
| Tier A | |
| Verified | |
| Cited in draft | |
| PDF needed from you | |
| Body words / budget | / |
| References heading on page | |

## Decisions taken (with date)
- {{e.g. 2026-09-23: Anthropic research reports accepted as sources}}

## Open items
- [ ] {{e.g. check WFH controls in Tucker, Lodefalk, Orr, Westby}}

## Waiting on you
- {{e.g. PDFs: list with links}}

## Last session summary
{{3 to 5 bullets}}
RKIT_EOF_15

mkdir -p "$T/skills/lit-review/method/templates"
cat > "$T/skills/lit-review/method/templates/kickoff-questions.md" <<'RKIT_EOF_16'
# Kickoff questions (ask all at once, in Phase 0)

Suggested defaults from the pilot review are in brackets.

## Brief
0. Paste the commissioning brief verbatim (e.g. the supervisor's email). Its length, structure and emphasis override the defaults below.

## Scope
1. Research question in one sentence, and the outcomes that count. [employment, hiring, hours, wages]
2. Heterogeneity dimensions that need their own section. [skill/experience, age]
3. Technology/treatment definition: what is in and out? [GenAI only; AI-broad and robots out]
4. Date floor for evidence. [2023]
5. Countries/regions: all, or a focus? [all; flag the OECD/non-OECD balance]

## Evidence standard
6. Causal only, or also descriptive work cited explicitly as a counterpoint? [causal; descriptive allowed only when labelled]
7. Accepted source types. [NBER, SSRN, arXiv, IZA, central banks, Census, journals, Anthropic research reports]
8. Pre-floor or out-of-scope papers used as *benchmarks*: allowed, and how many? [yes, ≤2, labelled "before GenAI"]
9. Minimum bar for "verified". [figures checked against full text or official abstract; press releases never count]

## Output
10. Length limit, and whether references count toward it. [3 pages of body; references may spill]
11. Format. [LaTeX `draft/review.tex` + `references.bib`, natbib authoryear, 11pt, 1in margins]
12. Structure. [definitions → micro evidence by design (one exemplar per design, the rest cited as a group) → theory explaining the patterns → evaluation; no introduction]
13. Audience and register. [academic, first person, claims first]

## Style (decided now, not after drafting)
14. Dashes and hyphens: allowed? [**none** in body text: rewrite compounds ("cover letter"), ranges as "22 to 24"]
15. Author name forms. [short form, e.g. "Hosseini" not "Hosseini Maasoum"]
16. Spelling. [British]
17. Anything to avoid (words, constructions). [see `method/style.md`: no "imprecise zero", "rule out", bare p-values, unglossed acronyms]
17b. Who is the reader, and what can they be assumed to know? [a smart economist who has not read these papers: define every measure, give every figure a comparison group]

## Inputs and access
18. Seed papers: which PDFs, and are any co-authored by people you work with?
19. Can you download paywalled/SSRN PDFs in one batch when asked? [yes]
20. Who else will read it, and should a daily update or email follow?
21. Where will you edit the draft (e.g. Overleaf)? That copy is the source of truth for every redraft.
RKIT_EOF_16

mkdir -p "$T/skills/lit-review/method/templates"
cat > "$T/skills/lit-review/method/templates/ledger-schema.md" <<'RKIT_EOF_17'
# Evidence ledger: `ledger.csv`

One row per paper. It is the single source of truth, replacing the separate
candidates, corrections, unverified-list and verification-log files. Append new
rows and update the `status`/`notes` fields; never delete rows.

| Column | Values / format | Example |
|---|---|---|
| `id` | short key, the same as the bib key once cited | `lambert2026broken` |
| `authors` | surnames, "; "-separated | `Lambert; Schindler` |
| `year` | version year | `2026` |
| `title` | exact title from the live source | `The Broken Ladder: AI, Remote Work, and Early-Career Hiring` |
| `venue_id` | series + number or DOI | `CAGE WP 808; SSRN 6787638` |
| `url` | live link that was checked | |
| `local_pdf` | path in `papers/` or scratch, or empty | `papers/lambert-schindler-2026-broken-ladder-ai-remote-work.pdf` |
| `source` | seed / backward / forward / deep-research / adversarial / user | `forward` |
| `seed_cites` | number of seeds citing it | `0` |
| `status` | found / screened-out / tier-A / tier-B / tier-C / pdf-needed / verified / cited / rejected / unverifiable | `cited` |
| `reason` | one line, for out/rejected/unverifiable | |
| `design` | RCT / quasi-exp / DiD / event study / IV / SDiD / descriptive / theory | `DiD` |
| `treatment` | how exposure or adoption is measured | `Eloundou exposure + WFH exposure` |
| `country` | ISO codes | `US;GB;CA;AU` |
| `period` | data window | `2017–2025` |
| `outcome_type` | productivity / stock / flow (hires) / postings / wages | `flow` |
| `headline` | figures exactly as the paper states them | `2 SD exposure → about −5pp junior share of hires; GenAI → ~0 jointly` |
| `fig_ref` | page or line in the PDF | `abstract; p.2` |
| `heterogeneity` | age/skill splits reported | |
| `confound_controls` | e.g. WFH, monetary policy, pre-trends | `WFH (joint)` |
| `provider` | data provider | `Revelio; Lightcast` |
| `version_checked` | date on the version read | `May 2026` |
| `retraction_checked` | yes / no + date | `yes 2026-09-23` |
| `notes` | free text | |

`templates/ledger.csv` holds this header row, ready to copy.
RKIT_EOF_17

mkdir -p "$T/skills/lit-review/method/templates"
cat > "$T/skills/lit-review/method/templates/ledger.csv" <<'RKIT_EOF_18'
id,authors,year,title,venue_id,url,local_pdf,source,seed_cites,status,reason,design,treatment,country,period,outcome_type,headline,fig_ref,heterogeneity,confound_controls,provider,version_checked,retraction_checked,notes
RKIT_EOF_18

mkdir -p "$T/skills/lit-review-digest"
cat > "$T/skills/lit-review-digest/SKILL.md" <<'RKIT_EOF_19'
---
name: lit-review-digest
description: Write a private per-paper digest for the user (at most half a page per paper; core idea, methodology, empirical strategy, data, assumptions, limitations, policy implications) from the PDFs and ledger of a literature review. Use when the user asks for paper summaries, a reading digest, "key ideas from each paper", or runs /lit-review-digest.
argument-hint: "[project-dir] [--papers id1,id2 | --all-cited]"
---

# /lit-review-digest

A study aid for you only, not for the commissioner. It complements the
review: the review compares papers; the digest explains each one so you can
discuss it without rereading it.

## Inputs
- The project's `ledger.csv` (rows with `status=cited`, or the ids passed).
- Each paper's local PDF in `papers/` (or extracted text in `raw-inputs/text/`).
  Long papers: read with `/pdf-chunker`. No PDF → write the digest from the
  official abstract only and mark it `abstract only`.

## Output
`digest/paper-digests.md` (and `digest/paper-digests.pdf` via pandoc if
available). One block per paper, in the order the review cites them (seeds
first), with this fixed template:

```markdown
### Author (year), *Short title*  — [type: theory | calibration | empirical | survey | essay]
**One line:** the paper's answer to the review's question, with its headline number.
- **Core idea:** the mechanism or argument, 2 sentences.
- **Methodology:** model or design in plain words (what is compared with what).
- **Empirical strategy:** identification or calibration: which variation or which targets pin down the key parameter. "None (pure theory)" is a valid answer.
- **Data:** source, country, period, sample size. "None" for pure theory.
- **Assumptions:** the 2 to 3 assumptions the result depends on most, each with what happens if it fails.
- **Limitations:** what the authors concede, then what critics or other papers in the review raise (name them).
- **Policy implications:** what follows for policy, as the authors state it; say "none stated" rather than invent one.
- **Use in the review:** the section and claim it supports; page refs for its figures.
```

## Rules
1. **At most half a page per paper**: 230 words maximum per block (count
   them; trim the Core idea and Methodology first). Plain words, the reader
   is a smart economist who has not read the paper.
2. Every figure comes from the paper, with a PDF page reference in
   parentheses, matching the ledger. Never a figure from a search snippet.
3. Distinguish what the paper shows from what it assumes: calibrated numbers
   are "the model gives", not "the paper finds".
4. Limitations name the other papers in the review that push back.
5. Start the file with a 5-line "How the papers fit together" map (which
   papers share a framework, which disagree, on which parameter), then a
   one-line index (author, year, type, headline).
6. Style: `~/.claude/skills/lit-review/method/style.md` ;
   English unless you ask for French; no em dashes.
7. Finish with a word count per block (script below) and fix any over 230.

```bash
python3 - <<'EOF'
import re
s=open('digest/paper-digests.md').read()
for b in re.split(r'\n(?=### )',s)[1:]:
    n=len(re.findall(r"[A-Za-z0-9%.$']+",b)); print(n, b.splitlines()[0][:70], '<-- OVER' if n>230 else '')
EOF
```

## Never
- Send the digest to anyone, or put it in the review's `draft/` folder.
- Edit files in `papers/` or existing files in `raw-inputs/`.
RKIT_EOF_19

mkdir -p "$T/skills/lit-review-verify"
cat > "$T/skills/lit-review-verify/SKILL.md" <<'RKIT_EOF_20'
---
name: lit-review-verify
description: Check that every citation in a LaTeX or markdown review supports the sentence it is attached to, using the local PDFs and the evidence ledger. Use before sending a draft, or when asked to "check my citations" or run /lit-review-verify.
argument-hint: "[path-to-tex] [--section <name>]"
---

# /lit-review-verify

1. **Extract** every sentence that carries a citation, with its line number and keys. Classify each claim: **finding** (a result, direction or number), **method** (a design or measure), **fact** (a statistic from a source), or **general** (points to a literature).
2. **Locate the source** for each key: the ledger row, then the PDF in `papers/` (extract text with `pdftotext`, or `/pdf-chunker` for long papers), then the official abstract online.
3. **Verify in parallel**: one subagent per paper, up to five at a time, each given the claims citing that paper and the source text. Strictness follows the type: findings and facts must match the paper's own wording, numbers, comparison group and design; methods must match what the authors did; general citations only need to be on topic.
4. **Verdict per claim**: supported, overstated, mismatch, or unverifiable, with the page or quote that decides it and a suggested rewording when it is not supported.
5. **Write the report** to `raw-inputs/<date>_citation-check.md`, mismatches first. Change the draft only after the author approves.
RKIT_EOF_20

mkdir -p "$T/skills/pdf-chunker"
cat > "$T/skills/pdf-chunker/SKILL.md" <<'RKIT_EOF_21'
---
name: pdf-chunker
description: Read a long PDF reliably in page chunks with page references. Use for any paper over 20 pages, or when a figure or definition must be traced to its page.
argument-hint: "[path-to-pdf] [--pages 10]"
---

# /pdf-chunker

1. Get the page count with `pdfinfo`.
2. Extract text in chunks of 10 pages (`pdftotext -f <first> -l <last> -layout`) into the scratch folder, one file per chunk, named with its page range.
3. Read the abstract and introduction chunk first, then the data and design sections, then the results tables and robustness checks the review relies on.
4. Record every figure, definition and design detail with its page number, in the ledger or the notes file the task names.
5. If a chunk extracts as garbled text (scanned pages, broken fonts), say so and list the pages to read from the rendered PDF instead.
RKIT_EOF_21

mkdir -p "$T/skills/plan-day"
cat > "$T/skills/plan-day/SKILL.md" <<'RKIT_EOF_22'
---
name: plan-day
description: Lay out a day (or a few days) of priorities in the user's "Claude plan" Google Calendar, with regular breaks, fixed appointments kept, and one colour per priority. Use when the user lists tomorrow's priorities with durations, says "put this in my calendar", or runs /plan-day.
argument-hint: "[tomorrow | <date>] then the list"
---

# /plan-day

Needs the Google Calendar connector (claude.ai > Settings > Connectors) and a
calendar named "Claude plan".

1. Read the list: priorities in order, durations, fixed times (meetings, lunch),
   start time. Read the user's other calendars for that day, without changing them.
2. Lay it out in order: blocks of at most about one hour, a 10-minute break
   after each, 15 minutes before an outside appointment. If something cannot
   fit before a fixed time, move a shorter item into the gap and say so.
3. Create the events in "Claude plan" only, with no attendees, so no
   invitation is sent. Put sub-steps in the event description.
4. Give each priority its own colour (Google colour IDs 1 to 11), breaks in one
   muted colour, meals in another.
5. Show the day as a table, then list: which durations you guessed, clashes with
   other calendars, anything left out (commute, exercise, reporting).
6. Changes ("add X to priority 8", "make it more colourful") edit the same
   events; never delete or change events in other calendars.
RKIT_EOF_22

mkdir -p "$T/skills/policy-analysis"
cat > "$T/skills/policy-analysis/SKILL.md" <<'RKIT_EOF_23'
---
name: policy-analysis
description: Analyse a public programme, policy proposal or reform from public sources only (official reports, statistics, evaluations, international comparisons) and turn it into short, neutral, sourced fiches, one per measure, with every number checked against the source material. Use when asked to analyse a programme, cost a measure, compare countries, or run /policy-analysis.
argument-hint: "new <topic> | lot <name> | check <lot> | resume"
---

# /policy-analysis

A pipeline for many measures at once: research agents gather the material,
one fiche is written per measure, and scripts check every number before
anything is shown to a reader.

## Folder
```
<project>/
  CLAUDE.md          scope, sources allowed, neutrality rule, audience (from kickoff)
  measures.csv       id, measure, source document, page, lot
  lots/<lot>/materiau.md   the research material, every figure with its source
  lots/<lot>/ledger.csv    one row per figure (schema: lit-review method/templates/ledger-schema.md)
  fiches/<id>.md     one fiche per measure (templates/fiche.md)
  checks/<lot>.txt   output of the checks
```

## Steps
1. **Kickoff** (`new`): ask in one message: the question; the programme or
   reform and its source documents; the measures in scope; the sources allowed
   (default: official statistics, public evaluations, audit offices, OECD/IMF/
   World Bank, peer-reviewed and working papers); the comparison countries; the
   audience and language; and the **neutrality rule** (default: describe and
   cost, never recommend or judge). Write the answers to `CLAUDE.md`. List the
   measures in `measures.csv` with page references and group them into lots of
   5 to 10.
2. **Research** (`lot <name>`): one subagent per lot, up to three in parallel,
   each briefed with `templates/agent-brief.md`. Each writes `materiau.md` and
   `ledger.csv` for its lot: what the measure changes, its cost (official
   costing first, then independent ones, with the year and the scope of each),
   the causal evidence on similar measures, and how two or three comparison
   countries do it. Figures only from the source itself; a press release or a
   search snippet is a lead, not a source.
3. **Fiches**: one per measure, from `templates/fiche.md`, using only the
   lot's `materiau.md`. If a second writer is installed (`gemini-write`),
   Claude writes the brief and Gemini the prose; Claude then checks it.
4. **Checks** (`check <lot>`):
   - `python3 -I scripts/check_numbers.py fiches/<id>.md lots/<lot>/materiau.md`
     lists every number in the fiche that is not in the material;
   - `python3 -I scripts/check_neutral.py fiches/<id>.md` flags evaluative
     words ("should", "better", "bad idea", "must");
   - the `citation-checker` agent confirms that each source says what the fiche says;
   - the `data-reviewer` agent re-derives any total, share or comparison computed by Claude.
   Save the output to `checks/<lot>.txt`. Fix factual errors only.
5. **Publish** (optional): assemble the fiches into one document or a static
   site page. Nothing is published, sent or pushed without the user's yes.

## Rules
- Public sources only. Never put personal or confidential data in a brief.
- Neutral by default: describe, cost and compare. A recommendation appears only
  if the kickoff asked for one, and then in a separate, labelled section.
- Every figure carries its year, its scope (who, where) and a comparison point.
- One measure, one fiche, one page at most.
RKIT_EOF_23

mkdir -p "$T/skills/policy-analysis/scripts"
cat > "$T/skills/policy-analysis/scripts/check_neutral.py" <<'RKIT_EOF_24'
#!/usr/bin/env python3
"""Flag evaluative wording in a fiche meant to be neutral.
Usage: python3 -I check_neutral.py fiche.md [more words, comma separated]"""
import re, sys
words = ["should", "must", "ought", "better", "worse", "bad idea", "good idea", "poorly designed",
         "well designed", "unfortunately", "fortunately", "il faudrait", "mieux vaut", "bonne idée",
         "mal conçu", "mal ciblé"] + (sys.argv[2].split(",") if len(sys.argv) > 2 else [])
text = open(sys.argv[1]).read()
hits = [(n + 1, w) for n, line in enumerate(text.splitlines()) for w in words if re.search(r"(?i)\b" + re.escape(w) + r"\b", line)]
for n, w in hits: print(f"line {n}: {w}")
print("evaluative wording:", len(hits))
sys.exit(1 if hits else 0)
RKIT_EOF_24

mkdir -p "$T/skills/policy-analysis/scripts"
cat > "$T/skills/policy-analysis/scripts/check_numbers.py" <<'RKIT_EOF_25'
#!/usr/bin/env python3
"""List the numbers in a draft that do not appear in the source material.
Usage: python3 -I check_numbers.py draft.md materiau.md"""
import re, sys
norm = lambda s: re.sub(r"[\s  ]", "", s)
draft, material = open(sys.argv[1]).read(), norm(open(sys.argv[2]).read())
missing = sorted({x.strip() for x in re.findall(r"\d[\d\s  ]*(?:[.,]\d+)?", draft)
                  if len(norm(x)) > 1 and norm(x) not in material})
print("not in the material:", missing if missing else "none")
sys.exit(1 if missing else 0)
RKIT_EOF_25

mkdir -p "$T/skills/policy-analysis/templates"
cat > "$T/skills/policy-analysis/templates/agent-brief.md" <<'RKIT_EOF_26'
You research lot <LOT> of a neutral policy analysis. Project rules are in CLAUDE.md; read it first.
Measures in this lot (from measures.csv): <LIST>.
For each measure, write to lots/<LOT>/materiau.md: what it changes (current rule vs proposed), its cost (official, then independent, each with year and scope), the causal evidence on similar measures (design, sample, comparison, result), and the same indicator for <COUNTRIES>.
Add one row per figure to lots/<LOT>/ledger.csv with the source, URL and page or table.
Sources allowed: <SOURCES>. A figure counts only if you read it in the source itself; press releases and search snippets are leads.
No judgement, no recommendation. Don't publish, send or commit anything. Report in under 150 words: rows added, measures with no costing, anything uncertain.
RKIT_EOF_26

mkdir -p "$T/skills/policy-analysis/templates"
cat > "$T/skills/policy-analysis/templates/fiche.md" <<'RKIT_EOF_27'
# <Measure, in the programme's own words> (<source document>, p. <n>)

**In one line:** what changes, for whom, from when.

## What changes
Current rule, proposed rule, people or institutions concerned (number, year, source).

## What it costs
Official costing (who, year, scope). Independent costings, with their differences explained.

## What the evidence says
Causal studies on this or similar measures: design, sample, comparison group, result. Agreeing studies cited as a group.

## How other countries do it
Two or three comparison countries, with the same indicator and year for each.

## What we don't know
The gaps, and what would settle them.

## Sources
Numbered list: author or institution, year, title, URL, page or table.
RKIT_EOF_27

mkdir -p "$T/skills/simulate-referee"
cat > "$T/skills/simulate-referee/SKILL.md" <<'RKIT_EOF_28'
---
name: simulate-referee
description: Simulate the first reader of a draft, an editor or supervisor plus two referees, before it is sent. Use when asked to "simulate a referee", "review as my supervisor would", or run /simulate-referee.
argument-hint: "[path-to-tex] [--brief <file or text>]"
---

# /simulate-referee

Run three separate subagents on the compiled draft, each without the drafting conversation:

1. **Editor or commissioner**: judge the draft against the brief (length, structure, emphasis, audience). Summarise the paper in three sentences and list what the brief asked for that is missing.
2. **Referee 1, domain expert**: coverage (key papers missing, papers misplaced), whether each claim matches what the cited paper found, and whether the conclusions follow from the evidence.
3. **Referee 2, methods expert**: for each study, whether the design is described precisely enough to judge it (data, treatment, comparison, timing, result), and which identification threats the review leaves unaddressed.

Each referee gives up to five major and five minor comments, each pointing to a line or section. Then write an editor's decision (accept, minor, major) with the five changes that matter most, and save everything to `raw-inputs/<date>_referee-simulation.md`. Do not edit the draft.
RKIT_EOF_28

zsh "$T/install.sh"
print "Kit files kept in $T (README.md explains each piece)."
