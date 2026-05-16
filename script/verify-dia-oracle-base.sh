#!/usr/bin/env bash
# Verify DIA PushOracleReceiverV2 on Base (0xCE521b52513242c5094bc56f57887BB2A05B8129).
#
# Requires:
#   ETHERSCAN_API_KEY — Basescan / Etherscan API v2 key
#   git, forge, cast (nix develop provides these)
#
# Usage:
#   export ETHERSCAN_API_KEY=your_key
#   ./script/verify-dia-oracle-base.sh

set -euo pipefail

ORACLE=0xCE521b52513242c5094bc56f57887BB2A05B8129
SPECTRA_REPO="${SPECTRA_REPO:-/tmp/diadata-spectra-interoperability}"
SPECTRA_REF="${SPECTRA_REF:-main}"

if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "error: set ETHERSCAN_API_KEY (Basescan API key)" >&2
  exit 1
fi

if [[ ! -d "$SPECTRA_REPO/.git" ]]; then
  # Do not use --recurse-submodules: config-private is a private DIA repo.
  git clone --depth 1 --branch "$SPECTRA_REF" \
    https://github.com/diadata-org/Spectra-interoperability.git "$SPECTRA_REPO"
fi

cd "$SPECTRA_REPO"

# Shallow clones omit submodule contents; forge remappings require lib/*.
git submodule update --init --depth 1 \
  contracts/lib/forge-std \
  contracts/lib/openzeppelin-contracts

if [[ ! -f contracts/lib/forge-std/src/Script.sol ]]; then
  echo "error: contracts/lib/forge-std not initialized" >&2
  exit 1
fi
if [[ ! -f contracts/lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol ]]; then
  echo "error: contracts/lib/openzeppelin-contracts not initialized" >&2
  exit 1
fi

cd contracts
npm install --silent

echo "Building PushOracleReceiverV2..."
forge build --contracts contracts/PushOracleReceiverV2.sol

CONSTRUCTOR_ARGS=$(
  cast abi-encode \
    "constructor(string,string,uint256,address)" \
    "DIA Oracle" "1.0" 1050 0x5612599cf48032d7428399d5fcb99edcc75c06a7
)

echo "Submitting verification to Basescan..."
forge verify-contract \
  "$ORACLE" \
  contracts/PushOracleReceiverV2.sol:PushOracleReceiverV2 \
  --chain base \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  --constructor-args "$CONSTRUCTOR_ARGS" \
  --watch

echo "Verified: https://basescan.org/address/$ORACLE#code"
