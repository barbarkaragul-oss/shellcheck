#!/bin/bash
# Runs INSIDE the haskell container. Mounts: /mnt=shellcheck-pr (has shellcheck-zsh), /corpus=zsh-corpus
set -u
ZSH=/mnt/shellcheck-zsh
STABLE=/corpus/shellcheck-stable
LIST=/corpus/zsh-files.txt
OUT=/corpus/report
mkdir -p "$OUT"

# baseline stable shellcheck (represents today's master behavior)
if [ ! -x "$STABLE" ]; then
  for V in v0.11.0 v0.10.0 v0.9.0; do
    if curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/$V/shellcheck-$V.linux.x86_64.tar.xz" -o /tmp/sc.txz 2>/dev/null; then
      tar xJf /tmp/sc.txz -C /tmp && cp /tmp/shellcheck-$V/shellcheck "$STABLE" && echo "baseline: $V" && break
    fi
  done
fi
echo "zsh bin: $($ZSH --version | grep version: )"
echo "stable bin: $($STABLE --version | grep version: )"

run_eval() {
  local bin="$1" tag="$2"
  local fatal=0 ok=0 total=0
  : > "$OUT/codes-$tag.txt"
  while IFS= read -r f; do
    [ -f "/corpus/$f" ] || continue
    total=$((total+1))
    out=$("$bin" -f gcc "/corpus/$f" 2>&1)
    echo "$out" | grep -oE 'SC[0-9]+' >> "$OUT/codes-$tag.txt"
    if echo "$out" | grep -qE 'SC1071|SC1072|SC1073|SC1077'; then fatal=$((fatal+1)); else ok=$((ok+1)); fi
  done < "$LIST"
  echo "$tag: total=$total parsed_ok=$ok fatal_parse_or_refusal=$fatal" | tee -a "$OUT/summary.txt"
}
: > "$OUT/summary.txt"
echo "=== PARSE ACCEPTANCE ===" | tee -a "$OUT/summary.txt"
run_eval "$STABLE" stable
run_eval "$ZSH" zsh
echo "=== top warning codes (zsh) ===" | tee -a "$OUT/summary.txt"
sort "$OUT/codes-zsh.txt" | uniq -c | sort -rn | head -25 | tee -a "$OUT/summary.txt"
echo "DONE"
