#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	cmake 			    \
  	glslang 		    \
  	hicolor-icon-theme  \
  	libao 				\
  	libcdio 			\
  	libjuice 			\
  	libzip 				\
  	lua 				\
 	miniupnpc 			\
	sdl2-compat 	    \
  	vulkan-headers

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini

echo "Building Flycast..."
echo "---------------------------------------------------------------"
REPO="https://github.com/flyinghead/flycast"
if [ "${DEVEL_RELEASE-}" = 1 ]; then
    echo "Making nightly build of Flycast..."
    echo "---------------------------------------------------------------"
    VERSION="$(git ls-remote "$REPO" HEAD | cut -c 1-9 | head -1)"
    git clone --recursive --depth 1 "$REPO" ./flycast
else
	echo "Making stable build of Flycast..."
	VERSION="$(git ls-remote --tags --sort="v:refname" "$REPO" | tail -n1 | sed 's/.*\///; s/\^{}//; s/^v//')"
	git clone --branch v"$VERSION" --single-branch --recursive --depth 1 "$REPO" ./flycast
fi
echo "$VERSION" > ~/version

# use system vulkan-headers
sed -E -e '/add_subdirectory/s&^.*Vulkan-Headers.*$&find_package(VulkanHeaders)&' -i ./flycast/CMakeLists.txt
# use system libjuice
sed -E -e 's&(LibJuice)Static&\1&' \
    -e '/add_subdirectory/s&^.*libjuice.*$&find_package(LibJuice)&' \
    -i ./flycast/CMakeLists.txt
# runtime page size on Linux aarch64
sed -E -e 's@^#if defined\(__ANDROID__\) && \(HOST_CPU == CPU_ARM64 \|\| HOST_CPU == CPU_X64\)$@#if (defined(__ANDROID__) || (defined(__linux__) \&\& HOST_CPU == CPU_ARM64)) \&\& (HOST_CPU == CPU_ARM64 || HOST_CPU == CPU_X64)@' \
    -i ./flycast/core/stdclass.h ./flycast/core/stdclass.cpp
grep -q 'defined(__linux__) && HOST_CPU == CPU_ARM64' ./flycast/core/stdclass.h

cmake -S ./flycast -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_TESTING=OFF \
    -DUSE_BREAKPAD=OFF \
    -DUSE_HOST_GLSLANG=ON \
    -DUSE_HOST_SDL=ON \
    -DUSE_LIBCDIO=ON
cmake --build build
cmake --install build
