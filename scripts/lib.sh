#!/usr/bin/env bash
# Shared paths and VERSIONS for hub-kernel scripts.
# Env vars already set (LINUX_COMMIT, CROSS_COMPILE, …) win over VERSIONS.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while IFS='=' read -r key val; do
	[[ -z "${key}" ]] && continue
	if [[ -z "${!key:-}" ]]; then
		export "${key}=${val}"
	fi
done < <(sed -E -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*\?=[[:space:]]*/=/' "${ROOT}/VERSIONS")

DL_DIR="${DL_DIR:-${ROOT}/dl}"
BUILD_DIR="${BUILD_DIR:-${ROOT}/build}"
STAGING_DIR="${STAGING_DIR:-${ROOT}/staging}"
DIST_DIR="${DIST_DIR:-${ROOT}/dist}"
LINUX_SRC="${LINUX_SRC:-${BUILD_DIR}/linux-${LINUX_COMMIT}}"
PACKAGE_DIR="${PACKAGE_DIR:-${STAGING_DIR}/package}"

export ARCH="${LINUX_ARCH}"
export CROSS_COMPILE
export DL_DIR BUILD_DIR STAGING_DIR DIST_DIR LINUX_SRC PACKAGE_DIR ROOT

# Kernel Make uses $(CC); wrap with ccache when present (cross gcc is not
# always in /usr/lib/ccache).
if command -v ccache >/dev/null 2>&1; then
	export CC="${CC:-ccache ${CROSS_COMPILE}gcc}"
	export HOSTCC="${HOSTCC:-ccache gcc}"
fi
