# Prebuilt Raspberry Pi 5 kernel for [BigFred hub OS](https://github.com/dcc-bigfred/bigfred-os).

This repository owns the **kernel source pin** and **kconfig fragments**.
CI cross-compiles `Image`, DTBs, overlays, and modules, then publishes a
tarball on GitHub Releases. `bigfred-os` should consume that tarball by
version + SHA-256 (same pattern as Grafana), not rebuild Linux inside
Buildroot.

The scripts in this repo are MIT. **The kernel binary and modules are GPLv2**
(`raspberrypi/linux`).

Target is **Pi 5 / BCM2712 only**. Pi 3 needs a separate defconfig and artifact.

## Build

On Ubuntu 24.04:

```bash
sudo ./scripts/install-deps.sh
make check
make package
```

`make package` writes `dist/bigfred-kernel-rpi5-<version>.tar.xz` and a
matching `.sha256`. Untagged builds use `g<shortsha>` as the version.

## Release

1. Bump `LINUX_COMMIT` in `VERSIONS` and the SHA in `configs/linux.hash` if
   moving the upstream pin (recompute with `sha256sum dl/linux-<commit>.tar.gz`).
2. Change fragments under `configs/` for hub `CONFIG_*` options.
3. Tag `v6.18.0-rN` (upstream version + rebuild counter). Same Linux commit
   with a fragment change is `-rN+1`.
4. Push the tag. `release.yml` attaches:

   - `bigfred-kernel-rpi5-v6.18.0-rN.tar.xz`
   - `bigfred-kernel-rpi5-v6.18.0-rN.tar.xz.sha256`

## Artifact layout

```
Image
bcm2712-rpi-5-b.dtb
bcm2712d0-rpi-5-b.dtb
overlays/*.dtbo          # includes bcm2712d0.dtbo
lib/modules/<krel>/
config                   # kernel .config
manifest
```

Modules are uncompressed (`CONFIG_MODULE_COMPRESS` is off) because musl
`kmod` on the hub image has failed to load XZ modules.

Compiler is Ubuntu `aarch64-linux-gnu-gcc`, not the Buildroot musl toolchain.
The kernel is freestanding; libc does not matter. Rebuilds are reproducible
against Ubuntu 24.04 + this pin.

## Consuming from bigfred-os

Pin a release tag and the SHA-256 of the tarball (Buildroot `.hash`). If the
committed hash matches the file in `dl/`, skip the download. A kernel
`CONFIG_*` change is a PR **here**, then a tag, then a hash bump in
`bigfred-os`.
