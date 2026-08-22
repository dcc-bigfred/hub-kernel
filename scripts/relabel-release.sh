#!/usr/bin/env bash
# Rename a CI tarball for a release tag and refresh manifest + sha256.
# Usage: relabel-release.sh <src.tar.xz> <tag> [out-dir]
set -euo pipefail

src="${1:?usage: $0 <src.tar.xz> <tag> [out-dir]}"
tag="${2:?usage: $0 <src.tar.xz> <tag> [out-dir]}"
out_dir="${3:-$(dirname "$src")}"

base="bigfred-kernel-rpi5-${tag}"
out_tar="${out_dir}/${base}.tar.xz"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

tar -xJf "${src}" -C "${tmpdir}"
if [[ -f "${tmpdir}/manifest" ]]; then
	sed -i "s/^version=.*/version=${tag}/" "${tmpdir}/manifest"
fi
tar -cJf "${out_tar}" -C "${tmpdir}" .
( cd "${out_dir}" && sha256sum "${base}.tar.xz" > "${base}.tar.xz.sha256" )

echo "wrote ${out_tar}"
cat "${out_dir}/${base}.tar.xz.sha256"
