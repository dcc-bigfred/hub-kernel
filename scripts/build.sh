#!/usr/bin/env bash
# Configure (bcm2712_defconfig + fragments) and build Image, dtbs, modules.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/scripts/lib.sh"

if [[ ! -f "${LINUX_SRC}/Makefile" ]]; then
	echo "error: kernel source missing; run scripts/fetch-src.sh first" >&2
	exit 1
fi

if ! command -v "${CROSS_COMPILE}gcc" >/dev/null 2>&1; then
	echo "error: ${CROSS_COMPILE}gcc not found (install gcc-aarch64-linux-gnu)" >&2
	exit 1
fi

jflag=()
if [[ "${MAKEFLAGS:-}" != *j* ]]; then
	jflag=(-j"$(nproc 2>/dev/null || echo 4)")
fi

bash "${ROOT}/scripts/apply-patches.sh"

cd "${LINUX_SRC}"

echo "Configuring ${LINUX_DEFCONFIG} + hub fragments"
make "${jflag[@]}" "${LINUX_DEFCONFIG}_defconfig"
./scripts/kconfig/merge_config.sh -m .config \
	"${ROOT}/configs/linux-4k-page-size.fragment" \
	"${ROOT}/configs/linux-hub.fragment"
make "${jflag[@]}" olddefconfig

echo "Building Image dtbs modules"
make "${jflag[@]}" Image dtbs modules

echo "Build finished: $(make -s kernelrelease)"
