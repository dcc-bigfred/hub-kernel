#!/usr/bin/env bash
# Stage Image, DTBs, overlays, modules and pack tar.xz + sha256.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/scripts/lib.sh"

if [[ ! -f "${LINUX_SRC}/arch/${LINUX_ARCH}/boot/Image" ]]; then
	echo "error: Image missing; run scripts/build.sh first" >&2
	exit 1
fi

version="${VERSION:-}"
if [[ -z "${version}" ]]; then
	if git -C "${ROOT}" describe --exact-match --tags HEAD >/dev/null 2>&1; then
		version="$(git -C "${ROOT}" describe --exact-match --tags HEAD)"
	else
		version="g$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
	fi
fi

krel="$(make -C "${LINUX_SRC}" -s kernelrelease)"
rm -rf "${STAGING_DIR}"
mkdir -p "${PACKAGE_DIR}/overlays" "${DIST_DIR}"

install -m 0644 "${LINUX_SRC}/arch/${LINUX_ARCH}/boot/Image" "${PACKAGE_DIR}/Image"
install -m 0644 "${LINUX_SRC}/.config" "${PACKAGE_DIR}/config"

copy_named_dtb() {
	local name="$1"
	local found
	found="$(find "${LINUX_SRC}/arch" -type f -name "${name}" -print -quit)"
	if [[ -z "${found}" ]]; then
		echo "error: ${name} not found under ${LINUX_SRC}/arch" >&2
		exit 1
	fi
	install -m 0644 "${found}" "${PACKAGE_DIR}/${name}"
}

copy_named_dtb bcm2712-rpi-5-b.dtb
copy_named_dtb bcm2712d0-rpi-5-b.dtb

overlay_dir=""
for d in \
	"${LINUX_SRC}/arch/arm/boot/dts/overlays" \
	"${LINUX_SRC}/arch/arm64/boot/dts/overlays" \
	"${LINUX_SRC}/arch/arm64/boot/dts/broadcom/overlays"; do
	if [[ -d "${d}" ]]; then
		overlay_dir="${d}"
		break
	fi
done
if [[ -z "${overlay_dir}" ]]; then
	echo "error: kernel overlay directory not found" >&2
	exit 1
fi
shopt -s nullglob
copied=0
for dtbo in "${overlay_dir}"/*.dtbo; do
	install -m 0644 "${dtbo}" "${PACKAGE_DIR}/overlays/"
	copied=$((copied + 1))
done
shopt -u nullglob
if [[ "${copied}" -eq 0 ]]; then
	echo "error: no .dtbo overlays in ${overlay_dir}" >&2
	exit 1
fi
if [[ ! -f "${PACKAGE_DIR}/overlays/bcm2712d0.dtbo" ]]; then
	echo "error: overlays/bcm2712d0.dtbo missing" >&2
	exit 1
fi

echo "Installing modules (${krel})"
jflag=()
if [[ "${MAKEFLAGS:-}" != *j* ]]; then
	jflag=(-j"$(nproc 2>/dev/null || echo 4)")
fi
make -C "${LINUX_SRC}" "${jflag[@]}" modules_install \
	INSTALL_MOD_PATH="${PACKAGE_DIR}" \
	INSTALL_MOD_STRIP=1
rm -f "${PACKAGE_DIR}/lib/modules/${krel}/build" \
	"${PACKAGE_DIR}/lib/modules/${krel}/source"

{
	echo "name=bigfred-kernel-rpi5"
	echo "version=${version}"
	echo "kernelrelease=${krel}"
	echo "linux_repo=${LINUX_REPO}"
	echo "linux_branch=${LINUX_BRANCH}"
	echo "linux_commit=${LINUX_COMMIT}"
	echo "defconfig=${LINUX_DEFCONFIG}"
} > "${PACKAGE_DIR}/manifest"

tar_name="bigfred-kernel-rpi5-${version}.tar.xz"
tar -C "${PACKAGE_DIR}" -cJf "${DIST_DIR}/${tar_name}" .
( cd "${DIST_DIR}" && sha256sum "${tar_name}" > "${tar_name}.sha256" )

echo "Packed ${DIST_DIR}/${tar_name}"
cat "${DIST_DIR}/${tar_name}.sha256"
