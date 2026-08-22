#!/usr/bin/env bash
# Download raspberrypi/linux at the pinned commit and verify SHA-256.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/scripts/lib.sh"

tar_name="linux-${LINUX_COMMIT}.tar.gz"
url="https://github.com/${LINUX_REPO}/archive/${LINUX_COMMIT}/${tar_name}"
out="${DL_DIR}/${tar_name}"

mkdir -p "${DL_DIR}" "${BUILD_DIR}"

if [[ -f "${out}" ]]; then
	echo "Using cached ${out}"
else
	echo "Fetching ${url}"
	curl -fL --retry 3 --retry-delay 2 -o "${out}.partial" "${url}"
	mv "${out}.partial" "${out}"
fi

expected="$(awk -v name="${tar_name}" '$1 == "sha256" && $3 == name { print $2; exit }' "${ROOT}/configs/linux.hash")"
if [[ -z "${expected}" ]]; then
	echo "error: no sha256 for ${tar_name} in configs/linux.hash" >&2
	exit 1
fi

actual="$(sha256sum "${out}" | awk '{ print $1 }')"
if [[ "${actual}" != "${expected}" ]]; then
	echo "error: hash mismatch for ${tar_name}" >&2
	echo "  expected ${expected}" >&2
	echo "  actual   ${actual}" >&2
	exit 1
fi

src="${BUILD_DIR}/linux-${LINUX_COMMIT}"
if [[ ! -f "${src}/Makefile" ]]; then
	echo "Extracting ${out}"
	rm -rf "${src}"
	tar -xf "${out}" -C "${BUILD_DIR}"
	# GitHub archive top-level is linux-<commit>/
	if [[ ! -d "${src}" ]]; then
		echo "error: expected ${src} after extract" >&2
		exit 1
	fi
fi

echo "Source ready: ${src}"
