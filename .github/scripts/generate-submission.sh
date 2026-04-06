#!/usr/bin/env bash
# Genereert PDF-documentatie en een code-zip voor inlevering bij de docent.
#
# Gebruik (lokaal):
#   cd <repo-root>
#   bash .github/scripts/generate-submission.sh
#
# Output (in ./output/):
#   cloud-automation-concepts.pdf
#   cloud-engineering-code.zip

set -euo pipefail

OUT_DIR="${OUT_DIR:-output}"
DATE=$(date +%d-%m-%Y)
GITHUB_BASE="https://github.com/Stensel8/cloud-engineering/blob/main"

mkdir -p "$OUT_DIR"

# LaTeX header: kleinere tabelletters zodat kolommen niet overflowen
LATEX_HEADER=$(mktemp --suffix=.tex)
cat > "$LATEX_HEADER" << 'TEX'
\usepackage{etoolbox}
\AtBeginEnvironment{longtable}{\small}
\AtBeginEnvironment{tabular}{\small}
TEX

PANDOC_OPTS=(
  --pdf-engine=xelatex
  --from markdown+raw_tex
  --variable "geometry:margin=1.5cm"
  --variable "fontsize=11pt"
  --variable "mainfont=DejaVu Serif"
  --variable "monofont=DejaVu Sans Mono"
  --variable "colorlinks=true"
  --variable "linkcolor=NavyBlue"
  --variable "urlcolor=NavyBlue"
  --highlight-style=tango
  --toc
  --toc-depth=3
  --include-in-header="$LATEX_HEADER"
)

# Schrijf relatieve markdown-links om naar absolute GitHub-URLs.
# Leest van stdin, schrijft naar stdout.
# $1 = URL-encoded subpad binnen de repo (bijv. "cloud-automation-concepts")
rewrite_links() {
  local subdir="$1"
  LINK_BASE="${GITHUB_BASE}/${subdir}" perl -pe '
    my $base = $ENV{LINK_BASE};
    # Herschrijf alleen relatieve links (niet http(s)://, #ankers, mailto:)
    s{(!?)\[([^\]]*)\]\((?!https?://|#|mailto:)([^)]+)\)}{$1 eq "!" ? "![$2]($3)" : "[$2]($base/$3)"}ge
  '
}

###############################################################################
# 1. cloud-automation-concepts.pdf
###############################################################################
echo "Genereren: cloud-automation-concepts.pdf"
COMBINED=$(mktemp --suffix=.md)
trap 'rm -f "$COMBINED" "$LATEX_HEADER"' EXIT

# README afkappen vóór repo-specifieke secties (Weekmateriaal, VS Code, AWS CLI)
readme="cloud-automation-concepts/README.md"
if [ -f "$readme" ]; then
  sed '/^---$/,$ d' "$readme" \
    | rewrite_links "cloud-automation-concepts" \
    >> "$COMBINED"
  printf '\n\n\\newpage\n\n' >> "$COMBINED"
else
  echo "  WAARSCHUWING: bestand niet gevonden: $readme" >&2
fi

# Strip <video> tags (werken niet in PDF), herschrijf links, voeg assignments toe
declare -A ASSIGNMENT_SUBDIRS=(
  ["cloud-automation-concepts/Assignment 1 - AWS Basics"]="cloud-automation-concepts/Assignment%201%20-%20AWS%20Basics"
  ["cloud-automation-concepts/Assignment 2 - Docker Swarm"]="cloud-automation-concepts/Assignment%202%20-%20Docker%20Swarm"
  ["cloud-automation-concepts/Assignment 3 - Orchestration"]="cloud-automation-concepts/Assignment%203%20-%20Orchestration"
)

for assignment_dir in \
  "cloud-automation-concepts/Assignment 1 - AWS Basics" \
  "cloud-automation-concepts/Assignment 2 - Docker Swarm" \
  "cloud-automation-concepts/Assignment 3 - Orchestration"
do
  readme="${assignment_dir}/README.md"
  subdir="${ASSIGNMENT_SUBDIRS[$assignment_dir]}"
  if [ -f "$readme" ]; then
    sed 's|<video[^>]*>.*</video>||g' "$readme" \
      | rewrite_links "$subdir" \
      >> "$COMBINED"
    printf '\n\n\\newpage\n\n' >> "$COMBINED"
  else
    echo "  WAARSCHUWING: bestand niet gevonden: $readme" >&2
  fi
done

# Resource paths zodat pandoc images kan vinden (meerdere paden, dubbele punt als scheidingsteken)
RESOURCE_PATH=".:\
cloud-automation-concepts/Assignment 1 - AWS Basics:\
cloud-automation-concepts/Assignment 2 - Docker Swarm:\
cloud-automation-concepts/Assignment 3 - Orchestration"

pandoc "$COMBINED" \
  "${PANDOC_OPTS[@]}" \
  --resource-path="$RESOURCE_PATH" \
  --metadata title="Cloud Automation Concepts" \
  --metadata author="Sten Tijhuis" \
  --metadata author="Wout Achterhuis" \
  --metadata date="$DATE" \
  --metadata lang="nl-NL" \
  -o "$OUT_DIR/cloud-automation-concepts.pdf"

echo "  Klaar: $OUT_DIR/cloud-automation-concepts.pdf"
trap - EXIT
rm -f "$COMBINED" "$LATEX_HEADER"

###############################################################################
# 2. cloud-engineering-code.zip
###############################################################################
echo "Genereren: cloud-engineering-code.zip"

zip -r "$OUT_DIR/cloud-engineering-code.zip" . \
  -x ".git/*" \
  -x ".git" \
  -x "*/.terraform/*" \
  -x "*.tfstate" \
  -x "*.tfstate.backup" \
  -x "*.tfplan" \
  -x "*/terraform.tfvars" \
  -x "*/node_modules/*" \
  -x "${OUT_DIR}/*" \
  -x "*.DS_Store" \
  -x "*.pyc" \
  > /dev/null

echo "  Klaar: $OUT_DIR/cloud-engineering-code.zip"

echo ""
echo "Alle bestanden gegenereerd in ${OUT_DIR}/:"
ls -lh "${OUT_DIR}/"
