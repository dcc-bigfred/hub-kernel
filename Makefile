# Prebuilt Raspberry Pi 5 kernel for BigFred hub OS.
# Requires: curl, tar, xz, sha256sum; for build also gcc-aarch64-linux-gnu
#   (sudo scripts/install-deps.sh on Ubuntu/Debian).

include VERSIONS

export LINUX_REPO LINUX_BRANCH LINUX_COMMIT LINUX_DEFCONFIG LINUX_ARCH CROSS_COMPILE

.PHONY: all help check fetch-src build package clean

all: package

help:
	@echo "hub-kernel — Raspberry Pi 5 (bcm2712) kernel for BigFred"
	@echo ""
	@echo "  make check      — pin/hash/layout sanity"
	@echo "  make fetch-src  — download raspberrypi/linux @ $(LINUX_COMMIT)"
	@echo "  make build      — Image + dtbs + modules"
	@echo "  make package    — dist/bigfred-kernel-rpi5-<version>.tar.xz"
	@echo "  make clean      — remove build/, staging/, dist/ (keeps dl/)"
	@echo ""
	@echo "Pin: $(LINUX_REPO) $(LINUX_BRANCH) $(LINUX_COMMIT)"
	@echo "Tag a release: git tag v6.18.0-r1 && git push origin v6.18.0-r1"

check:
	bash scripts/check.sh

fetch-src:
	bash scripts/fetch-src.sh

build: fetch-src
	bash scripts/build.sh

package: build
	bash scripts/package.sh

clean:
	rm -rf build staging dist
