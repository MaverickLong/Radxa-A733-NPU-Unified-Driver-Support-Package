#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ko="$script_dir/aw_nna_galcore/galcore.ko}"
[[ -f "$ko" ]] || { echo "missing module: $ko" >&2; exit 1; }

if (( EUID != 0 )); then
  echo "[sudo] re-exec under root for insmod/rmmod" >&2
  exec sudo -E "$0" "$@"
fi

echo "[probe] running kernel: $(uname -r)"
echo "[probe] galcore vermagic: $(modinfo -F vermagic "$ko")"

# --- Pre-flight: don't load galcore alongside vipcore ----------------------
if lsmod | awk '{print $1}' | grep -qx vipcore; then
  echo "[unload] vipcore is loaded; unbinding from any platform device first" >&2
  drv=/sys/bus/platform/drivers/vipcore
  if [[ -d "$drv" ]]; then
    for dev_link in "$drv"/*; do
      [[ -L "$dev_link" && -e "$dev_link/uevent" ]] || continue
      name=$(basename "$dev_link")
      echo "  unbind $name"
      echo "$name" > "$drv/unbind" || true
    done
  fi
  echo "[unload] rmmod vipcore"
  rmmod vipcore
fi

# Make doubly sure no stale /dev/galcore symlink is in the way.
if [[ -L /dev/galcore ]]; then
  echo "[cleanup] removing stale /dev/galcore symlink"
  rm -f /dev/galcore
fi

# An existing (possibly older-version) galcore — rmmod before reloading.
# Necessary when swapping userspace/kernel ABI to a matching pair.
if lsmod | awk '{print $1}' | grep -qx galcore; then
  echo "[unload] galcore is already loaded; rmmod before reinsert" >&2
  rmmod galcore
fi

# --- Load it ---------------------------------------------------------------
echo "[load] insmod $ko"
insmod "$ko"

echo "---"
ls -la /dev/galcore || echo "warning: /dev/galcore did NOT appear; check dmesg below"
echo "---"
echo "tail of dmesg:"
dmesg --human | tail -30

chmod 777 /dev/galcore
