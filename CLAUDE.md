# CLAUDE.md

LaTeX resume that builds to PDF and Markdown from a shared source.
See [MAINTAINING.md](MAINTAINING.md) for the architecture, which files to edit,
and how variants work. Read it before changing how anything is built.

Quick orientation: edit `content/<variant>.tex` for resume content. `master.tex`
and `markdown.tex` are styling wrappers. `README.md` and `pdf/` are generated —
never edit them by hand.

## Finishing a change

Do not create commits. After making changes, do two things:

**1. Summarize what changed** — a short plain-language recap of the work.

**2. Output a ready-to-run commit command** in a copy-pasteable code block,
using one `-m` for the summary line and one additional `-m` per change:

```
git commit -m "Summary of change" -m "- Change"
```

With several changes:

```
git commit -m "Add print format with icon header" -m "- Load fontawesome5 only in the print branch so online builds work without it" -m "- Build every variant in both formats, naming print output <variant>-print.pdf" -m "- Document icon customization in MAINTAINING.md"
```

Rules for the commit command:

- **Cover every uncommitted change in the working tree, not just the work done
  since the last commit command you printed.** Check `git status` and
  `git diff HEAD` before writing it. A command printed earlier in the
  conversation was never run — if more work happened after it, the next command
  supersedes it and must describe the whole diff against `HEAD`. Printing a
  command that covers only the latest slice silently drops the earlier work from
  the commit message.
- Summary line: imperative mood, no trailing period (`Add X`, not `Added X.`).
- Each `-m` bullet starts with `- ` and states one concrete change.
- Keep it on a single line so it pastes into a terminal in one go.
- **Never include a `Co-Authored-By` trailer or any mention of Claude, AI
  assistance, or generated-with attribution.** These commits are authored by
  the repo owner.
