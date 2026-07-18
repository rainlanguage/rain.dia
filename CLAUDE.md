# Project instructions

## V3 IntOrAString

- DIA feed keys use V3 `IntOrAString`, not the legacy encoding.
- String bytes are right-aligned above the low byte. The low byte is
  `0xE0 | length`; read the length from its low five bits and the data from
  `value >> 8`.

## Generated artifacts

- Run `./script/build.sh` for canonical regeneration.
- Preserve this order: `script/BuildAuthoringMeta.sol` writes the raw authoring
  meta, `rain meta build` writes `meta/DiaWords.rain.meta`, then
  `script/Build.sol` writes `src/generated/DiaWords.pointers.sol`.
- The pipeline runs `script/Build.sol` twice so generated constants and compiled
  bytecode reach a self-consistent fixed point. Require a clean `git diff` after
  regeneration; the generated `DESCRIBED_BY_META_HASH` must equal
  `keccak256(meta/DiaWords.rain.meta)`.

## Fork golden re-pins

- Pin `FORK_BLOCK_BASE` in `test/lib/LibFork.sol` before updating golden values.
- For every tested symbol, query the pinned block with:
  `cast call 0xCE521b52513242c5094bc56f57887BB2A05B8129 "getValue(string)(uint128,uint128)" SYMBOL --rpc-url https://mainnet.base.org --block BLOCK`.
- Update the expected raw price, update timestamp comments, and fork timestamp
  documentation together, then run the full fork test suite.
