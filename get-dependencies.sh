#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    clang \
    sdl2-compat

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini ! llvm

if [ "${DEVEL_RELEASE-}" = 1 ]; then
	package=flycast-git
else
	package=flycast
fi
make-aur-package "$package"
pacman -Q "$package" | awk '{print $2; exit}' > ~/version
