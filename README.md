# Radxa A733 NPU Unified Driver Support Package

This repository includes helpers to make the unified driver to actually work on a
Radxa Cubie A7 Series SBC (Tested with A7Z) so that [TIM-VX](https://github.com/VeriSilicon/TIM-VX) works.

I have had numerous frustrations trying to get things work. I hope you don't suffer from the same, hence the repo in here.

## Prerequisites and Limitations

The Unified NPU SDK **does NOT work with the official Radxa OS till date**, unless Vivante / Allwinner / Radxa provide a userspace driver with lower glibc target, or unless Radxa decides to release their Debian 12 image.

Thankfully, we have [a custom Armbian build for the Radxa A733 SBCs](https://github.com/NickAlilovic/build) with newer glibc, which made this project possible.

The driver patch in this repo is for Linux 6.6 only. Link to tested image: [Radxa-cubie-a7z-v0.6.2_trixie_vendor_6.6.98_xfce_desktop](https://github.com/NickAlilovic/build/releases/download/Radxa-a7z-v0.6.2/Radxa-cubie-a7z-v0.6.2_trixie_vendor_6.6.98_xfce_desktop.img.xz). This image is for SD card only, but the v0.6.3 UFS image should also work.

This driver conflicts with existing VIPLite driver, i.e., `/dev/vipcore`. You need some extra work for VIPLite Driver to work along with Unified Driver (not covered in here).

## How to

Run `apply_galcore_6.6_drift.bash`, `build_galcore.bash`, `load_galcore.bash` (sudo permission needed), in the order. `/dev/vipcore` should be replaced by `/dev/galcore`.
