#!/usr/bin/env bash
# SPDX-License-Identifier: LicenseRef-DCL-1.0
# SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
# Regenerate committed meta artifacts (and fixtures) that the rainix
# copy-artifacts reusable diff-checks. Runs in the repo default devshell
# because `rain` (and node, where used) are not in rainix sol-shell.
set -euo pipefail
nix develop -c bash -euxo pipefail -c '
  mkdir -p meta
  forge script --silent ./script/BuildAuthoringMeta.sol
  rain meta build -i <(cat ./meta/DiaSubParserAuthoringMeta.rain.meta) -m authoring-meta-v2 -t cbor -e deflate -l none -o meta/DiaWords.rain.meta
'
