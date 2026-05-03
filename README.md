# Radxa A733 NPU Unified Driver Support Package

This repository includes helpers to make the unified driver to actually work on a
Radxa Cubie A7 Series SBC (Tested with A7Z) so that [TIM-VX](https://github.com/VeriSilicon/TIM-VX) works.

While not tested, this repository should also work for T527 Series SBCs should you find the appropriate OS image.

I have had numerous frustrations trying to get things work. I hope you don't suffer from the same, hence the repo in here.

## What and why

This repository contains patches and one-click install for the kernel-side unified driver, version `6.4.15.3.690884` for Vivante VIP9000 series NPU on Linux kernel 6.6. The kernel driver is meant for Linux kernel 5.5, so the patches here make sure it works with higher kernel versions.

Do note that we cannot use the newer `6.4.18.6.904649` in [Radxa-provided allwinner-bsp](https://github.com/radxa/allwinner-bsp/tree/cubie-aiot-v1.4.6/drivers/npu/aw_nna_galcore), because the only available user-space unified driver for A733/T527, released in the [Radxa-provided ai-sdk](https://github.com/ZIFENG278/ai-sdk/tree/main/unified-tina/lib/aarch64-none-linux-gnu), has a version of `6.4.15.3.690884`. Mixing different versions of the kernel and user-space drivers can cause the NPU to malfunction.

## Prerequisites and Limitations

The Unified NPU SDK **does NOT work with the official Radxa OS till date**, unless Vivante / Allwinner / Radxa provide a userspace driver with lower glibc target, or unless Radxa decides to release their Debian 12 image.

Thankfully, we have [a custom Armbian build for the Radxa A733 SBCs](https://github.com/NickAlilovic/build) with newer glibc, which made this project possible.

The driver patch in this repo is for Linux 6.6 only. Link to tested image: [Radxa-cubie-a7z-v0.6.2_trixie_vendor_6.6.98_xfce_desktop](https://github.com/NickAlilovic/build/releases/download/Radxa-a7z-v0.6.2/Radxa-cubie-a7z-v0.6.2_trixie_vendor_6.6.98_xfce_desktop.img.xz). This image is for SD card only, but the v0.6.3 UFS image should also work.

This driver conflicts with existing VIPLite driver, i.e., `/dev/vipcore`. You need some extra work for VIPLite Driver to work along with Unified Driver (not covered in here).

## Known issues

There are various issues with the currect state unified driver. These are tested on Radxa Cubie A7Z only, but they should be able to be generalised to any A733 / T527 Radxa SBCs.

- With TIM-VX, any operation requiring matrix multiplication (convolutions, fully-connected layers) must first **explicitly** convert its operands to the UINT8 data type. The graph fails to compile otherwise.

- General batched matrix multiplication does not work with this NPU. This means `tim::vx::MatMul` does not work. You will have to use a fully connected operation to mimic a general matric multiplication.

## How to

1. Run `apply_galcore_6.6_drift.bash`, `build_galcore.bash`, `load_galcore.bash` (sudo permission needed), in the order. `/dev/vipcore` should be replaced by `/dev/galcore`.

Once the driver is up and running, you should see the following logs from dmesg:

```
[  +0.545410] [  T14048] npu[36e0][36e0] unregister cooling
[  +0.000598] [  T14048] npu[36e0][36e0] remove opp freq: 492000000
[  +0.000092] [  T14048] npu[36e0][36e0] remove opp freq: 852000000
[  +0.000088] [  T14048] npu[36e0][36e0] remove opp freq: 1008000000
[  +0.004101] [  T14059] vipdrv_drv_platform_uninit 905 SUCCESS
[  +0.067351] [  T14063] galcore: enter gckPLATFORM_Init from allwinenertech
[  +0.000314] [  T14063] galcore: enter _GetPower
[  +0.000039] [  T14063] galcore: irq line = 477
[  +0.000006] [  T14063] galcore: ####################enter _AdjustParam ######################
[  +0.000005] [  T14063] galcore: galcore irq number is 477.
[  +0.000004] [  T14063] galcore: xp galcore irq number is 477.
[  +0.001220] [  T14063] Unable to find node
[  +0.004491] [  T14063] NPU Use VF1, use freq 1008
[  +0.005222] [  T14063] Get NPU VOL FAIL!
[  +0.004235] [  T14063] galcore: _AdjustParam 269 SUCCESS
[  +0.000084] [  T14063] NPU AXI CLK NULL
[  +0.004158] [  T14063] NPU AHB CLK NULL
[  +0.004094] [  T14063] CLK Frequency Get Failed! Use parent clk!
[  +0.006469] [  T14063] galcore: _AdjustParam rate:0
[  +0.000153] [  T14063] Galcore version 6.4.15.3.690884
[  +0.007866] [  T14063] galcore: _SetPower 0 ON
[  +0.003594] [  T14063] galcore: _SetPower 0 OFF
```

There are many failures, but they are basically all noise. If the log looks like something like this, and if you can find the device at `/dev/galcore`, it means the NPU is up and running.

2. To run programs based on the unified driver with TIM-VX, you need to compile TIM-VX against the external Vivante userspace driver in the [Radxa-provided ai-sdk](https://github.com/ZIFENG278/ai-sdk/tree/main/unified-tina/lib/aarch64-none-linux-gnu). Point the `EXTERNAL_VIV_SDK` cmake option to the SDK. You will need to re-arrange folder path to allow cmake to find the path correctly.
