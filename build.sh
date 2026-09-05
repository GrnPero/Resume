#!/bin/bash
# Regenerates every PDF in pdf/ and the resume section of README.md.
# Run manually, or let hooks/pre-commit run it for you. See MAINTAINING.md.
set -euo pipefail
cd "$(dirname "$0")"

DEFAULT_VARIANT=fullstack
mkdir -p pdf .build

# pandoc's gfm writer changes its formatting between releases -- 2.x indents
# bullets and leaves "|" literal, 3.x does neither. Either output is valid
# Markdown, but CI byte-compares README.md against a fresh build, so a machine
# on a different pandoc produces a README that CI rejects as stale even though
# the content is identical. Pinning one version is what makes that check mean
# "the sources changed" instead of "your pandoc differs". CI installs the same
# version from .pandoc-version -- bump both together, never just one.
PANDOC_VERSION=$(cat .pandoc-version)
have=$(pandoc --version | head -1 | awk '{print $2}')
if [[ $have != "$PANDOC_VERSION" ]]; then
  cat >&2 <<EOF
error: pandoc $have found, but this repo pins $PANDOC_VERSION (.pandoc-version)

Generating README.md with a different pandoc produces cosmetic diffs that CI
reports as a stale README. Install the pinned version:

  curl -fL -o /tmp/pandoc.deb https://github.com/jgm/pandoc/releases/download/$PANDOC_VERSION/pandoc-$PANDOC_VERSION-1-amd64.deb
  sudo dpkg -i /tmp/pandoc.deb

See "Why pandoc is pinned" in MAINTAINING.md.
EOF
  exit 1
fi

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
    if ! latexmk -pdf -jobname="$job" -outdir=.build \
                 -interaction=nonstopmode -halt-on-error \
                 -usepretex="\\def\\variant{$name}\\def\\format{$fmt}" \
                 -silent master.tex >".build/$job.build.log" 2>&1; then
      echo "error: LaTeX build failed for $job" >&2
      cat ".build/$job.build.log" >&2
      exit 1
    fi
    cp ".build/$job.pdf" "pdf/$job.pdf"
  done
done

echo "building README.md"
cp readme-header.md README.md
pandoc markdown.tex -t gfm --wrap=none --shift-heading-level-by=1 >> README.md

echo "done (README shows the '$DEFAULT_VARIANT' variant)"
