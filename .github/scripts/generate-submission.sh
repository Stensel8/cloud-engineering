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
DATE=$(date +%Y-%m-%d)

mkdir -p "$OUT_DIR"

PANDOC_OPTS=(
  --pdf-engine=xelatex
  --from gfm
  --variable "geometry:margin=2.5cm"
  --variable "fontsize=11pt"
  --variable "mainfont=DejaVu Serif"
  --variable "monofont=DejaVu Sans Mono"
  --variable "colorlinks=true"
  --variable "linkcolor=NavyBlue"
  --variable "urlcolor=NavyBlue"
  --highlight-style=tango
  --toc
  --toc-depth=3
)

# Voeg een bestand toe aan de gecombineerde markdown (als het bestaat).
# Elk bestand eindigt met een pagina-einde.
append() {
  local file="$1"
  if [ -f "$file" ]; then
    cat "$file" >> "$COMBINED"
    printf '\n\n\\newpage\n\n' >> "$COMBINED"
  else
    echo "  WAARSCHUWING: bestand niet gevonden: $file" >&2
  fi
}

###############################################################################
# 1. cloud-automation-concepts.pdf
###############################################################################
echo "Genereren: cloud-automation-concepts.pdf"
COMBINED=$(mktemp --suffix=.md)
trap 'rm -f "$COMBINED"' EXIT

# README afkappen vóór repo-specifieke secties (Weekmateriaal, VS Code, AWS CLI)
readme="cloud-automation-concepts/README.md"
if [ -f "$readme" ]; then
  sed '/^---$/,$ d' "$readme" >> "$COMBINED"
  printf '\n\n\\newpage\n\n' >> "$COMBINED"
else
  echo "  WAARSCHUWING: bestand niet gevonden: $readme" >&2
fi

# Strip <video> tags (werken niet in PDF) en voeg assignments toe
for assignment_dir in \
  "cloud-automation-concepts/Assignment 1 - AWS Basics" \
  "cloud-automation-concepts/Assignment 2 - Docker Swarm" \
  "cloud-automation-concepts/Assignment 3 - Orchestration"
do
  readme="${assignment_dir}/README.md"
  if [ -f "$readme" ]; then
    sed 's|<video[^>]*>.*</video>||g' "$readme" >> "$COMBINED"
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
rm -f "$COMBINED"

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
