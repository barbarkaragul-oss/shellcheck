#!/bin/bash
set -u
ZSH=/mnt/shellcheck-zsh; MASTER=/mnt/shellcheck-master; OUT=/corpus/report
mkdir -p "$OUT"
ident=0; diffc=0; total=0; skip=0; : > "$OUT/regression-diffs.txt"
while IFS= read -r f; do
  p="/bash/$f"; [ -f "$p" ] || continue; total=$((total+1))
  a=$(timeout 20 "$MASTER" -f gcc "$p" 2>&1); ra=$?
  b=$(timeout 20 "$ZSH" -f gcc "$p" 2>&1); rb=$?
  if [ $ra -eq 124 ] || [ $rb -eq 124 ]; then skip=$((skip+1)); continue; fi
  if [ "$a" = "$b" ]; then ident=$((ident+1)); else diffc=$((diffc+1)); echo "DIFF $f" >> "$OUT/regression-diffs.txt"; fi
done < /bash/bash-files.txt
echo "REGRESSION (bash/sh, master-binary vs zsh-binary): compared=$((ident+diffc)) identical=$ident differing=$diffc timed_out_skipped=$skip" | tee "$OUT/regression.txt"
: > "$OUT/examples.txt"
for f in $(grep -E 'ohmyzsh|prezto|zsh-completions' /corpus/zsh-files.txt | head -250); do
  o=$(timeout 15 "$ZSH" -f gcc "/corpus/$f" 2>&1 | grep -E 'SC2168|SC2086|SC2155|SC2046|SC2206' | head -1)
  [ -n "$o" ] && echo "$o" >> "$OUT/examples.txt"
done
echo "example lines: $(wc -l < "$OUT/examples.txt")" | tee -a "$OUT/regression.txt"
echo "DONE2"
