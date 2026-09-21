# adrienjoly.github.io (working title)

Personal academic site, rebuilt from https://sites.google.com/view/adrienjoly/home
Plain HTML + one CSS file — no build step, no framework, so it's easy to
edit directly (open a `.html` file, change the text, save).

## Structure
```
index.html      — home / bio
cv.html         — links to the CV PDF (same Drive link as the current site)
research.html   — working papers
writing.html    — op-eds, blog posts, policy briefs
assets/style.css
assets/photo.jpg  — NOT ADDED YET, drop a real photo here (index.html already references it and fails gracefully if missing)
```

## Content still pending
- Profile photo (`assets/photo.jpg`)
- Home page "Reading & piano" section — stub only, ties into the
  reading/piano tracking already set up under `_system/culture/` in the
  wider Claude Code system; fill in once there's something real to show
- CV: currently just links out to the same Google Drive PDF as the
  current site. Swap for an inline PDF or HTML version if wanted later.

## Deploying to GitHub Pages
Not done yet — this is a local build for review first. To go live:
```bash
gh repo create ajoly35.github.io --public --source=. --remote=origin
git add -A && git commit -m "Initial site"
git push -u origin main
```
Site would then be live at `https://ajoly35.github.io` within a few minutes.
Needs explicit go-ahead first — creating the repo and the first push are
both gated per the confirmation rules.
