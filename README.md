# rain.dia

Rain subparser and extern word for [DIA](https://diadata.org/) oracle V2.

## Usage

Provides a `dia-price` word that fetches prices from the DIA oracle on-chain.

```rain
using-words-from <DiaWords address>
price updated-at: dia-price("AMZN" 3600);
```

### Inputs

1. **key** — DIA price feed key as a string, e.g. `"AMZN"`, `"NVDA"`. Passed
   through directly to the DIA oracle contract.
2. **staleAfter** — Maximum age of the price in seconds. Reverts if the price is
   older than this.

### Outputs

1. **price** — The asset price as a Float (18 decimal places).
2. **updatedAt** — The timestamp of the last price update as a Float (unix
   seconds).

## Supported chains

- Base (8453)

## Development

```sh
# Build
forge build

# Run tests (requires Base RPC)
forge test

# Regenerate authoring meta, final contract meta, then generated pointers
./script/build.sh
```

`script/build.sh` is the canonical artifact pipeline. It enters the default Nix
development shell when needed, writes
`meta/DiaSubParserAuthoringMeta.rain.meta`, builds `meta/DiaWords.rain.meta`,
and finally runs `script/Build.sol` so `src/generated/DiaWords.pointers.sol`
hashes the final meta.

### Pre-commit

Git hooks use the committed `.pre-commit-config.yaml` (not Nix store symlinks).
Install once, then hooks run on `git commit`:

```sh
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

Solidity formatting runs when `forge` is on `PATH` (e.g. inside `nix develop`);
otherwise the hook is skipped so IDE commits still work. Run
`nix develop -c forge fmt` before committing `.sol` changes if needed.
