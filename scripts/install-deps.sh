#!/usr/bin/env bash
# Host packages for Ubuntu/Debian kernel cross-build.
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
	echo "error: run as root (sudo $0)" >&2
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
	build-essential \
	bc \
	bison \
	flex \
	libssl-dev \
	libncurses-dev \
	gcc-aarch64-linux-gnu \
	binutils-aarch64-linux-gnu \
	ccache \
	ca-certificates \
	curl \
	xz-utils \
	tar \
	git
