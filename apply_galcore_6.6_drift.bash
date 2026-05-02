#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
patch="$script_dir/galcore_6.6_kernel_api_drift.patch"
[[ -f "$patch" ]] || { echo "missing patch file: $patch" >&2; exit 1; }

bsp_root="${1:-$script_dir/aw_nna_galcore}"
[[ -f "$bsp_root" ]] || { echo "missing Allwinner BSP package: $bsp_root" >&2; exit 1; }

cd "$bsp_root"

# Already applied? Then re-applying would error out — bail cleanly.
if git apply --reverse --check "$patch" >/dev/null 2>&1; then
  echo "[apply] $(basename "$patch") already applied to $bsp_root — nothing to do" >&2
  exit 0
fi

# Probe forward apply; if that fails the tree is in some other state we
# don't want to touch.
if ! git apply --check "$patch" >/dev/null 2>&1; then
  echo "[apply] $(basename "$patch") doesn't apply cleanly to $bsp_root" >&2
  echo "  (tree is probably already partially modified; aborting without changes)" >&2
  exit 1
fi

git apply "$patch"
echo "[apply] applied $(basename "$patch") to $bsp_root" >&2
