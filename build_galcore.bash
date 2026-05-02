#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src_dir="${1:-$script_dir/aw_nna_galcore}"
[[ -d "$src_dir" ]] || { echo "missing source dir: $src_dir" >&2; exit 1; }

# Different vendor commits ship the build glue as either Kbuild or
# Makefile — pick whichever is present.
build_file=""
for candidate in Kbuild Makefile; do
  [[ -f "$src_dir/$candidate" ]] && { build_file="$candidate"; break; }
done
[[ -n "$build_file" ]] || {
  echo "no Kbuild or Makefile in $src_dir" >&2; exit 1;
}

kdir="/lib/modules/$(uname -r)/build"
[[ -d "$kdir" ]] || {
  echo "kernel headers missing for $(uname -r) (expected $kdir)" >&2
  echo "install linux-headers-$(uname -r) (or equivalent) first." >&2
  exit 1
}

# Patch the include paths if we haven't already. The vendor uses
# `$(srctree)/$(src)/...` which only resolves correctly for in-tree
# builds; for OOT (M=$PWD), `$(srctree)/$(src)` would expand to
# `<linux-headers>/<absolute-module-path>/...` and break.  Rewrite to
# `$(M)/...` once. Idempotent: a second run sees no $(srctree)/$(src)
# left and is a no-op. Backup kept as <build_file>.bak.
if grep -q 'srctree)/\$(src)' "$src_dir/$build_file"; then
  cp "$src_dir/$build_file" "$src_dir/$build_file.bak"
  sed -i 's|$(srctree)/$(src)|$(M)|g' "$src_dir/$build_file"
  echo "[patch] $build_file: \$(srctree)/\$(src) -> \$(M)" \
       "(backup: $src_dir/$build_file.bak)" >&2
fi

echo "[build] make -C $kdir M=$src_dir CONFIG_AW_NNA_GALCORE=m modules" >&2
make -C "$kdir" \
     M="$src_dir" \
     CONFIG_AW_NNA_GALCORE=m \
     modules

echo "---" >&2
ko="$src_dir/galcore.ko"
[[ -f "$ko" ]] || { echo "build finished but $ko not produced" >&2; exit 1; }
file "$ko"
modinfo -F vermagic "$ko"
echo "$ko"
