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
2. **staleAfter** — Staleness threshold of the price in seconds. Reverts unless
   the age of the price is strictly less than this, so a price exactly this old
   is stale.

### Outputs

1. **price** — The asset price as a Float (18 decimal places).
2. **updatedAt** — The timestamp of the last price update as a Float (unix
   seconds).

## Supported chains

- Base (8453)

## Development

Run all commands from the repository root. On a clean clone, install the pinned
Soldeer dependencies first:

```sh
nix develop -c forge soldeer install

# Build
nix develop -c forge build

# Run tests (requires Base RPC; set `BASE_RPC_URL` in CI)
nix develop -c forge test

# Regenerate authoring meta, final contract meta, then generated pointers
nix develop -c ./script/build.sh

# Equivalent standalone regeneration without entering the dev shell
nix run .#rain-dia-prelude
```

`script/build.sh` is the single implementation of the artifact pipeline. It uses
the repo dev shell when `forge` and `rain` are not already on `PATH` (e.g.
rainix copy-artifacts CI). The Nix commands above provide both tools. The script
writes `meta/DiaSubParserAuthoringMeta.rain.meta`, builds
`meta/DiaWords.rain.meta`, and finally runs `script/Build.sol` so
`src/generated/DiaWords.pointers.sol` hashes the final meta.

### Pre-commit

Entering `nix develop` generates `.pre-commit-config.yaml` as an untracked
symlink into the Nix store and installs the configured hooks. The symlink is
machine-specific and must not be committed. Run all hooks manually with:

```sh
nix develop -c pre-commit run --all-files
```

Run `nix develop -c forge fmt --check` before committing Solidity changes.
