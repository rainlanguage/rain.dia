#!/usr/bin/env bash
# SPDX-License-Identifier: LicenseRef-DCL-1.0
# SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
# Regenerate all committed codegen artifacts in dependency order.
set -euo pipefail

if ! command -v forge >/dev/null 2>&1 || ! command -v rain >/dev/null 2>&1; then
  echo "error: forge and rain are required; run 'nix run .#rain-dia-prelude'" >&2
  exit 127
fi

mkdir -p meta
forge script --silent ./script/BuildAuthoringMeta.sol
rain meta build \
  -i <(cat ./meta/DiaSubParserAuthoringMeta.rain.meta) \
  -m authoring-meta-v2 \
  -t cbor \
  -e deflate \
  -l none \
  -o meta/DiaWords.rain.meta
forge script --silent ./script/Build.sol
