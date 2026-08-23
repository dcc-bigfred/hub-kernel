#!/usr/bin/env bash
# Apply hub-kernel patches/linux/*.patch onto ${LINUX_SRC}. Idempotent via stamp.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/scripts/lib.sh"

if [[ ! -f "${LINUX_SRC}/Makefile" ]]; then
	echo "error: kernel source missing (${LINUX_SRC}); run scripts/fetch-src.sh first" >&2
	exit 1
fi

stamp="${LINUX_SRC}/.hub-patches-applied"
patch_dir="${ROOT}/patches/linux"

if [[ -f "${stamp}" ]]; then
	echo "Patches already applied (${stamp})"
	exit 0
fi

shopt -s nullglob
patches=("${patch_dir}"/*.patch)
shopt -u nullglob

if [[ ${#patches[@]} -eq 0 ]]; then
	touch "${stamp}"
	exit 0
fi

echo "Applying ${#patches[@]} hub patch(es)"
for p in "${patches[@]}"; do
	echo "  $(basename "${p}")"
	patch -d "${LINUX_SRC}" -p1 --forward --batch < "${p}"
done
touch "${stamp}"
echo "Patches applied"
