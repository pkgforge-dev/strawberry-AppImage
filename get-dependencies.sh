#!/bin/sh

set -eux

ARCH="$(uname -m)"
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

pacman -Syu --noconfirm \
	base-devel       \
	boost            \
	cmake            \
	curl             \
	git              \
	gst-plugins-bad  \
	libxcb           \
	libxcursor       \
	libxi            \
	libxkbcommon     \
	libxkbcommon-x11 \
	libxrandr        \
	libxtst          \
	pipewire-audio   \
	pulseaudio       \
	pulseaudio-alsa  \
	qt6ct            \
	qt6-tools        \
	qt6-wayland      \
	rapidjson        \
	sparsehash       \
	wget             \
	xorg-server-xvfb \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-mesa --prefer-nano qt6-base-mini libxml2-mini opus-mini

echo "Building strawberry..."
echo "---------------------------------------------------------------"
sed -i 's|EUID == 0|EUID == 69|g' /usr/bin/makepkg
git clone https://gitlab.archlinux.org/archlinux/packaging/packages/strawberry
cd ./strawberry
makepkg -fs --skippgpcheck
pacman -U --noconfirm ./*.pkg.tar.zst

pacman -Q strawberry | awk '{print $2; exit}' > ~/version
