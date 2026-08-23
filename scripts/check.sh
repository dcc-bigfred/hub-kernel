#!/usr/bin/env bash
# Sanity-check repo layout, pin/hash consistency, and script syntax.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/scripts/lib.sh"

err=0

need() {
	if [[ ! -e "$1" ]]; then
		echo "missing: $1" >&2
		err=1
	fi
}

need "${ROOT}/configs/linux-4k-page-size.fragment"
need "${ROOT}/configs/linux-hub.fragment"
need "${ROOT}/configs/linux.hash"
need "${ROOT}/VERSIONS"
need "${ROOT}/scripts/fetch-src.sh"
need "${ROOT}/scripts/build.sh"
need "${ROOT}/scripts/apply-patches.sh"
need "${ROOT}/scripts/package.sh"
need "${ROOT}/patches/linux"

tar_name="linux-${LINUX_COMMIT}.tar.gz"
if ! grep -qE "^sha256[[:space:]]+[0-9a-f]{64}[[:space:]]+${tar_name}\$" "${ROOT}/configs/linux.hash"; then
	echo "error: configs/linux.hash must contain sha256 for ${tar_name}" >&2
	err=1
fi

if [[ "${LINUX_DEFCONFIG}" != "bcm2712" ]]; then
	echo "error: LINUX_DEFCONFIG must be bcm2712 (Pi 5); got ${LINUX_DEFCONFIG}" >&2
	err=1
fi

for s in fetch-src.sh build.sh apply-patches.sh package.sh relabel-release.sh check.sh install-deps.sh lib.sh; do
	bash -n "${ROOT}/scripts/${s}"
done

shopt -s nullglob
patches=("${ROOT}/patches/linux"/*.patch)
shopt -u nullglob
if [[ ${#patches[@]} -eq 0 ]]; then
	echo "error: no patches in patches/linux/" >&2
	err=1
fi
for p in "${patches[@]}"; do
	if ! grep -qE '^From:' "${p}"; then
		echo "error: ${p} missing From: header" >&2
		err=1
	fi
	if ! grep -qE '^Subject:' "${p}"; then
		echo "error: ${p} missing Subject: header" >&2
		err=1
	fi
done

if [[ "${err}" -ne 0 ]]; then
	exit 1
fi
echo "check ok (commit ${LINUX_COMMIT}, ${LINUX_BRANCH})"
