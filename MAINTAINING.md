# Maintaining this repo

How the resume is built, which files to edit, and how to add tailored versions.

## Architecture

```
content/
  _header.tex          contact info, shared by every variant
  _education.tex       education, shared by every variant
  fullstack.tex        the default variant (what README.md shows)
master.tex             PDF wrapper: preamble + macros that produce a PDF
markdown.tex           Markdown wrapper: same macros, Markdown-shaped
build.sh               regenerates everything
readme-header.md       the intro block prepended to README.md
hooks/pre-commit       runs build.sh and stages the results
pdf/                   generated PDFs
README.md              generated
```

**Generated — never edit by hand:** `README.md`, everything in `pdf/`. Both are
overwritten on the next build.

### Why content and presentation are split

The resume content lives in `content/` and uses only semantic macros
(`\resumeItem`, `\resumeSubheading`, …). Those macros are then defined *twice* —
once in `master.tex` for the PDF, once in `markdown.tex` for Markdown.

This exists because a resume PDF leans on two-column `tabular*` layouts,
`\scshape`, `\underline`, and hand-tuned `\vspace` to look right. None of that
has a Markdown equivalent, so converting the PDF source directly produces
unusable output — fenced `::: center` divs, `<span>` noise, and broken
pseudo-tables. Defining the macros semantically for the Markdown target sidesteps
the problem entirely instead of trying to clean up the mess afterwards.

## Two dimensions: variant and format

|  | What it controls | Where it lives |
|---|---|---|
| **Variant** (`fullstack`, …) | What the resume *says* | `content/` |
| **Format** (`online`, `print`) | How the contact header *looks* | `master.tex` |

Every variant is built in both formats:

- **`pdf/<variant>.pdf` — online.** Contact details as underlined text
  hyperlinks. Send this to job portals and recruiters.
- **`pdf/<variant>-print.pdf` — print.** Contact details as FontAwesome icon
  glyphs. Print this to hand to someone.

**Icons are kept out of the online version on purpose.** Icon glyphs come from
an icon font, and many applicant-tracking systems mangle or silently drop them
along with the contact detail sitting next to them. A LinkedIn logo that looks
sharp on paper can turn your profile URL into nothing in a resume parser. Paper
has no clickable links, so that is where icons earn their place.

## Which file do I edit?

| I want to… | Edit |
|---|---|
| Change a bullet, job, or skill | `content/<variant>.tex` |
| Change contact info | `content/_header.tex` (updates every variant) |
| Change education | `content/_education.tex` |
| Change how the PDF looks | `master.tex` |
| Change how the Markdown looks | `markdown.tex` |
| Change the README intro | `readme-header.md` |

Day to day you only touch `content/fullstack.tex`.

## Adding a tailored variant

```bash
cp content/fullstack.tex content/backend.tex
# edit the skills and bullets in the copy
./build.sh
```

`build.sh` discovers variants automatically — there is nothing to register.
`pdf/backend.pdf` (and `-print`) appear on the next build. Contact info and
education stay shared, so updating your phone number once updates every variant.

Files prefixed `_` are shared partials, not variants; the build skips them.

Add a download link to `readme-header.md` if you want the new variant listed on
the repo page.

## One-off variants for a specific company

For a resume tailored to a single application that you do not want committed:

```bash
cp content/fullstack.tex content/local-companyA.tex
# edit the bullets
./build.sh          # produces pdf/local-companyA.pdf
```

Both `content/local-*.tex` and `pdf/local-*.pdf` are gitignored. The variant
builds and the PDF is yours to send, but neither ever enters git — not in a
commit, not in history, not visible on GitHub. The pre-commit hook's
`git add pdf/` skips ignored files, so one cannot slip in by accident.

This matters beyond tidiness: a resume tailored to one employer is usually not
something you want other employers reading in a public repo.

Two consequences of staying untracked — it will not follow you to another
machine, and it is not backed up. If one turns out to be worth keeping, drop the
`local-` prefix and it becomes a normal tracked variant.

## Building

```bash
./build.sh
```

Writes `pdf/*.pdf` and regenerates `README.md`. Intermediate LaTeX files go to
`.build/` (gitignored), which is why `pdf/` stays free of `.aux`/`.log` clutter.

## First-time setup on a new clone

```bash
sudo apt-get install pandoc latexmk \
  texlive-latex-base texlive-latex-recommended texlive-latex-extra \
  texlive-fonts-recommended texlive-fonts-extra

git config core.hooksPath hooks
```

`texlive-fonts-extra` is the large one (~1–2 GB) and supplies `fontawesome5`.
Skip it and everything still works apart from the print PDFs — `build.sh` warns
and builds the online versions only.

The `git config` line is required because git deliberately does not let a repo
configure its own `hooksPath`; a repo that could silently run scripts on clone
would be a security hole. There is no way around it in plain git, so it is a
one-time manual step per clone.

## Customizing print icons

The print header is defined in the `print` branch of the `\resumeHeader`
conditional in `master.tex` — icons are presentation, so they never appear in
`content/`. It pairs an icon command with each contact field:

```latex
\faPhone\ #2 $|$ \faEnvelope\ #3 \\
\faLinkedin\ #4 $|$ \faGithub\ #5
```

The trailing `\ ` after each icon is a real space; without it the glyph collides
with the text.

To swap an icon, change the command. Useful ones: `\faGlobe` (portfolio),
`\faMapMarker` (location), `\faFilePdf`, `\faStackOverflow`. Run
`texdoc fontawesome5` for the full searchable list.

To add a whole new contact field (a portfolio URL, say), that one *does* touch
content: add the argument in `content/_header.tex`, then bump the argument count
and render it in **both** header definitions in `master.tex` **and** in
`markdown.tex`. All three must agree on the argument count or the build errors.

If icons render as blank boxes rather than logos, the package resolved but the
font did not — check `.build/*.log` for missing-glyph warnings before assuming
the icon name is wrong.

## How generation works

The pre-commit hook runs `build.sh` and stages `README.md` and `pdf/` whenever
you commit a change to the resume sources, so generated files land in *your*
commit. Nothing regenerates them afterwards, which means there is never a bot
commit to pull.

CI only inspects: it compiles the LaTeX to catch a typo that breaks the build,
and checks that the committed `README.md` matches what the sources produce. It
never commits or pushes.

**If CI reports a stale README**, the commit was made without the hook (usually
`core.hooksPath` was never set on that clone). Fix it with:

```bash
./build.sh
git add README.md pdf/
git commit --amend --no-edit
git push --force-with-lease
```
