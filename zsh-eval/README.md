# zsh support — reproducible corpus evaluation

Backs the numbers posted on koalaman/shellcheck#3645. Measures three things against a
real-world zsh corpus:

1. **Parse acceptance** — does it parse real zsh, instead of the v0.3.5 state where
   `-s zsh` was accepted but parsing failed on most scripts.
2. **No regression** — on bash/sh, the zsh build is byte-identical to a master build.
3. **Value** — the warnings actually produced.

## Results from the reference run

| | fatal (SC1071 / SC1072 / SC1073 / SC1077) |
|---|---|
| ShellCheck v0.11.0 | 628 / 2195 |
| zsh build | **82 / 2195 (96.3% parse)** |

Regression (bash/sh, master build vs zsh build, `-f gcc`): **59 / 59 byte-identical, 0 differences**.

See `results/`.

## Reproduce (needs Docker)

```sh
# 0. a checkout of shellcheck
# 1. build both binaries with the same toolchain
git checkout <zsh-branch>
docker run --rm -v "$PWD:/mnt" -v "$PWD/.cabal:/root/.cabal" -w /mnt haskell:9.6.6 \
  bash -c 'cabal build exe:shellcheck && cp $(cabal list-bin shellcheck) /mnt/shellcheck-zsh'
git checkout master
docker run --rm -v "$PWD:/mnt" -v "$PWD/.cabal:/root/.cabal" -w /mnt haskell:9.6.6 \
  bash -c 'cabal build exe:shellcheck && cp $(cabal list-bin shellcheck) /mnt/shellcheck-master'

# 2. fetch the corpus
bash zsh-eval/fetch-corpus.sh
cp zsh-eval/eval.sh zsh-eval/eval2.sh zsh-corpus/

# 3. parse acceptance (downloads the v0.11.0 baseline)
docker run --rm -v "$PWD:/mnt" -v "$PWD/zsh-corpus:/corpus" haskell:9.6.6 bash /corpus/eval.sh

# 4. regression + examples (provide a bash/sh corpus under ./bash-corpus with bash-files.txt)
docker run --rm -v "$PWD:/mnt" -v "$PWD/zsh-corpus:/corpus" -v "$PWD/bash-corpus:/bash" \
  haskell:9.6.6 bash /corpus/eval2.sh
```

The binaries are dynamically linked against the build image, so run them inside the same
`haskell:9.6.6` image. Corpus: oh-my-zsh, prezto, zsh-completions, zimfw, and zsh's own
`Completion/` + `Functions/` (2,195 files in the reference run).
