#!/bin/bash
# Regenerates every PDF in pdf/ and the resume section of README.md.
# Run manually, or let hooks/pre-commit run it for you. See MAINTAINING.md.
set -euo pipefail
cd "$(dirname "$0")"

DEFAULT_VARIANT=fullstack
mkdir -p pdf .build

# The print format needs fontawesome5 (texlive-fonts-extra). Skip those builds
# rather than failing if it is missing, so commits still work without it.
FORMATS=(online)
if kpsewhich fontawesome5.sty >/dev/null 2>&1; then
  FORMATS+=(print)
else
  echo "warning: fontawesome5 not found (install texlive-fonts-extra)" >&2
  echo "         building online PDFs only, skipping print versions" >&2
fi

for f in content/*.tex; do
  name=$(basename "$f" .tex)
  [[ $name == _* ]] && continue   # _-prefixed files are shared partials

  for fmt in "${FORMATS[@]}"; do
    if [[ $fmt == online ]]; then job="$name"; else job="$name-print"; fi
    echo "building pdf/$job.pdf"
    # Everything (PDF + aux) is written to .build, then only the PDF is
    # copied out -- that keeps pdf/ free of .aux/.log/.fls clutter.
    # -usepretex is how the variant/format flags reach LaTeX; passing them as
    # part of the filename makes latexmk reject the argument.
    latexmk -pdf -jobname="$job" -outdir=.build \
            -interaction=nonstopmode -halt-on-error \
            -usepretex="\\def\\variant{$name}\\def\\format{$fmt}" \
            master.tex >/dev/null
    cp ".build/$job.pdf" "pdf/$job.pdf"
  done
done

echo "building README.md"
cp readme-header.md README.md
pandoc markdown.tex -t gfm --wrap=none --shift-heading-level-by=1 >> README.md

echo "done (README shows the '$DEFAULT_VARIANT' variant)"
