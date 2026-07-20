#!/usr/bin/env bash
# Verify the pinned DiaWords Zoltu CREATE2 deployment.
#
# forge script --verify against Etherscan fails for Zoltu factory CALLs with:
#   "Compiled contract deployment bytecode does NOT match the transaction
#    deployment bytecode."
# Sourcify matches the on-chain runtime bytecode and is the reliable path.
set -euo pipefail

ADDRESS="$(
  sed -nE 's/.*DIA_WORDS_DEPLOYED_ADDRESS = (0x[0-9A-Fa-f]+);/\1/p' \
    src/lib/deploy/LibDiaWordsDeploy.sol | head -n1
)"
if [[ -z "${ADDRESS}" ]]; then
  echo "Failed to read DIA_WORDS_DEPLOYED_ADDRESS from LibDiaWordsDeploy.sol" >&2
  exit 1
fi

CONTRACT="src/concrete/DiaWords.sol:DiaWords"
CHAIN="${VERIFY_CHAIN:-base}"

creation_tx=""
broadcast_json="broadcast/Deploy.sol/8453/run-latest.json"
if [[ -f "${broadcast_json}" ]]; then
  # Zoltu factory call: transaction.to is the factory, input is creation code.
  creation_tx="$(
    jq -r '
      .transactions[]
      | select(.transaction.to != null)
      | select(.transaction.to | ascii_downcase == "0x7a0d94f55792c434d74a40883c6ed8545e406d12")
      | .hash
    ' "${broadcast_json}" | head -n1
  )"
fi

echo "Verifying DiaWords at ${ADDRESS} on ${CHAIN} via Sourcify"
forge verify-contract \
  "${ADDRESS}" \
  "${CONTRACT}" \
  --chain "${CHAIN}" \
  --verifier sourcify \
  --watch

# Best-effort Basescan/Etherscan verify. Zoltu CREATE2 often still fails here;
# do not fail the job if it does — Sourcify above is the required gate.
if [[ -n "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "Attempting Etherscan/Basescan verification for ${ADDRESS}"
  etherscan_args=(
    forge verify-contract
    "${ADDRESS}"
    "${CONTRACT}"
    --chain "${CHAIN}"
    --verifier etherscan
    --etherscan-api-key "${ETHERSCAN_API_KEY}"
    --watch
  )
  if [[ -n "${creation_tx}" ]]; then
    echo "Using creation transaction ${creation_tx}"
    etherscan_args+=(--creation-transaction-hash "${creation_tx}")
  fi
  if ! "${etherscan_args[@]}"; then
    echo "Etherscan/Basescan verification failed (known limitation for Zoltu CREATE2)." >&2
    echo "Sourcify verification already succeeded." >&2
  fi
fi
