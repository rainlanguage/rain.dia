# rain.dia

Rain subparser and extern word for [DIA](https://diadata.org/) oracle V2.

## Usage

Provides a `dia-price` word that fetches prices from the DIA oracle on-chain.

```rain
using-words-from <DiaWords address>
price updated-at: dia-price("BTC/USD" 3600);
```

### Inputs

1. **key** — DIA price feed key as a string, e.g. `"BTC/USD"`, `"ETH/USD"`. Passed through directly to the DIA oracle contract.
2. **staleAfter** — Maximum age of the price in seconds. Reverts if the price is older than this.

### Outputs

1. **price** — The asset price as a Float (8 decimal places).
2. **updatedAt** — The timestamp of the last price update as a Float (unix seconds).

## Supported chains

- Base (8453)

## Development

```sh
# Build
forge build

# Run tests (requires Base RPC)
forge test

# Regenerate pointers
forge script script/BuildPointers.sol
```
