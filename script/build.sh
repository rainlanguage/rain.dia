#!/usr/bin/env bash
# SPDX-License-Identifier: LicenseRef-DCL-1.0
# SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
# Regenerate all committed codegen artifacts in dependency order.
# Runs in the repo default devshell when `rain` is not on PATH (e.g. rainix
# copy-artifacts sol-shell).
set -euo pipefail

build_artifacts() {
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
  forge script --silent ./script/Build.sol
}

if command -v forge >/dev/null 2>&1 && command -v rain >/dev/null 2>&1; then
  build_artifacts
else
  export -f build_artifacts
  nix develop -c bash -euxo pipefail -c build_artifacts
fi
