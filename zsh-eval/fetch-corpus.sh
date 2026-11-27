#!/bin/bash
# Clones a real-world zsh corpus into ./zsh-corpus and writes zsh-files.txt
set -e
mkdir -p zsh-corpus && cd zsh-corpus
for r in ohmyzsh/ohmyzsh zsh-users/zsh-completions zimfw/zimfw sorin-ionescu/prezto zsh-users/zsh; do
  d=$(basename "$r"); [ -d "$d" ] || git clone --depth 1 "https://github.com/$r" "$d"
done
{
  find ohmyzsh -type f \( -name '*.zsh' -o -name '*.zsh-theme' \)
  find ohmyzsh -type f -path '*completions/_*'
  find ohmyzsh -type f -name '_*' -path '*plugins*'
  find zsh-completions/src -type f -name '_*' 2>/dev/null
  find zimfw -type f -name '*.zsh'
  find prezto -type f \( -name '*.zsh' -o -path '*functions/*' \)
  find zsh/Completion -type f -name '_*' 2>/dev/null
  find zsh/Functions -type f 2>/dev/null
} | sort -u > zsh-files.txt
echo "zsh files: $(wc -l < zsh-files.txt)"
