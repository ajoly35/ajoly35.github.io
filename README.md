# ajoly35.github.io

Personal academic site, rebuilt from https://sites.google.com/view/adrienjoly/home
Live at https://ajoly35.github.io. Plain HTML + one CSS file — no build
step, no framework, so it's easy to edit directly (open a `.html` file,
change the text, save, commit, push).

## Structure
```
index.html      — home / bio
cv.html         — CV, hosted directly as assets/cv.pdf
research.html   — working papers
writing.html    — op-eds, blog posts, policy briefs
talks.html      — panels, talks, events organised or hosted
assets/style.css
assets/favicon.svg
assets/photo.jpg  — profile photo
assets/cv.pdf     — current CV
assets/talks/     — event photos
```

## Updating
Edit the relevant `.html` file directly, then from this folder:
```bash
git add -A && git commit -m "..."
git push
```
Nothing pushes automatically — commit and push are separate, deliberate
steps each time.

## Still open (see CHECKLIST.md for the full, current list)
- Talks page: confirm exact wording for the European Conference role,
  add a date for the Puga interview, confirm everyone in the group
  photos is comfortable being on a public site.
- Old Google Sites page: point it at the new site, or unpublish it.
- Optional: custom domain via a `CNAME` file.
