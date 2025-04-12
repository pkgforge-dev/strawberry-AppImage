#!/bin/sh

set -eu

PACKAGE=strawberry
DESKTOP=org.strawberrymusicplayer.strawberry.desktop
ICON=strawberry.png

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION=$(pacman -Q "$PACKAGE" | awk 'NR==1 {print $2; exit}')
echo "$VERSION" > ~/version

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

# Prepare AppDir
mkdir -p ./AppDir/shared/lib
cd ./AppDir

cp -v /usr/share/applications/"$DESKTOP"            ./
cp -v /usr/share/icons/hicolor/128x128/apps/"$ICON" ./
cp -v /usr/share/icons/hicolor/128x128/apps/"$ICON" ./.DirIcon

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -s -k -e \
	/usr/bin/strawberry* \
	/usr/lib/libgst* \
	/usr/lib/gstreamer-*/*.so \
	/usr/lib/qt6/plugins/iconengines/* \
	/usr/lib/qt6/plugins/imageformats/* \
	/usr/lib/qt6/plugins/platforms/* \
	/usr/lib/qt6/plugins/platformthemes/* \
	/usr/lib/qt6/plugins/styles/* \
	/usr/lib/qt6/plugins/sqldrivers/* \
	/usr/lib/qt6/plugins/tls/* \
	/usr/lib/qt6/plugins/xcbglintegrations/* \
	/usr/lib/qt6/plugins/wayland-*/* \
	/usr/lib/pulseaudio/* \
	/usr/lib/pipewire-*/* \
	/usr/lib/spa-*/*/*

# DEPLOY GSTREAMER
echo "Deploying Gstreamer binaries..."
cp -vn /usr/lib/gstreamer-*/*  ./shared/lib/gstreamer-* || true

# Patch a relative interpreter for the gstreamer plugins
echo "Sharunning Gstreamer bins..."
rm -f ./shared/lib/gstreamer-1.0/libgstopengl* || true
for plugin in ./shared/lib/gstreamer-1.0/gst-*; do
	if file "$plugin" | grep -i 'elf.*executable'; then
		mv "$plugin" ./shared/bin && ln -s ../../../sharun "$plugin"
		echo "Sharan $plugin"
	else
		echo "$plugin is not a binary, skipping..."
	fi
done

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# Remove bloats
echo "Removing bloats..."
rm -f ./shared/lib/libLLVM* ./shared/lib/libgallium* || true

# MAKE APPIMAGE WITH URUNTIME
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
printf "$UPINFO" > data.upd_info
llvm-objcopy --update-section=.upd_info=data.upd_info \
	--set-section-flags=.upd_info=noload,readonly ./uruntime
printf 'AI\x02' | dd of=./uruntime bs=1 count=3 seek=8 conv=notrunc

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime \
	-i ./AppDir -o "$PACKAGE"-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"
