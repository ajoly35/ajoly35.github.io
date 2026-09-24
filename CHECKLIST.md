# Presentable-site checklist (ajoly35.github.io)

_Drafted 2026-09-24. The site is live (GitHub Pages, `main` branch); local changes only go live after a commit and push._

## Blocking: visible to visitors today
- [ ] **Push today's changes** (Talks page, nav link, photos). Until then `ajoly35.github.io/talks.html` returns 404, and the CV now links to it.
- [ ] **Profile photo**: add `assets/photo.jpg` (square, at least 256 × 256 px). The live home page currently shows a dashed "Add photo" box.
- [ ] **Remove the note to Claude on the CV page** (`cv.html`: "drop the PDF into assets/ and tell Claude…"). It is visible to visitors.
- [ ] **Remove or fill the "Reading & piano" stub** on the home page ("Not filled in yet…").
- [ ] **Replace the CV PDF**: the Drive file linked from the home and CV pages is the old version (Nielsen wording, Google Sites URL, no STICERD link). Either overwrite that Drive file with `~/Downloads/Adrien_Joly_CV_updated.pdf` (keeps the same link) or put the PDF in `assets/cv.pdf` and link to it.

## Talks page: confirm before or soon after publishing
- [ ] European Conference: your role. The page says "Opening the panel" (from the lectern photo) and the CV says you conceived and hosted it. Adjust if you were organiser, moderator or introducer.
- [ ] Benoît Puga interview at LSE: add the date (month and year), and the name of the organising society if relevant.
- [ ] Nadia Crisan photo: your note says "at Princeton"; the LISD trip was in Paris and Berlin. The caption currently gives no location. Add one if you know it.
- [ ] Group photos show other students (Philippe, Puga). Make sure people in them are comfortable being on a public site.

## Polish
- [ ] Favicon (`favicon.ico` currently 404).
- [ ] Open Graph tags (`og:title`, `og:description`, `og:image`) so links shared on LinkedIn, X and WhatsApp show a preview.
- [ ] Check that every Google Drive link (CV, 2 research drafts, 2 writing pieces) is set to "Anyone with the link can view".
- [ ] Home page "Background": add the current fellowship with Xavier Jaravel (as in the CV) and a one-line research focus.
- [ ] Writing page: check it lists the Harvard French Review (2026) and TechPolicy.Press pieces from the CV.
- [ ] Check the site on a phone. The navigation now has 5 links and wraps.
- [ ] Update `README.md`: the title still says `adrienjoly.github.io`, and the "Deploying" section describes a repo that already exists.
- [ ] Point the old Google Sites page to the new site (a single line at the top of the home page), or unpublish it once the new one is complete.
- [ ] Optional: custom domain (e.g. `adrienjoly.com`) via a `CNAME` file.
