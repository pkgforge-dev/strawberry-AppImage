#!/bin/sh

set -eu

PACKAGE=strawberry
DESKTOP=org.strawberrymusicplayer.strawberry.desktop
ICON=strawberry.png
TARGET_BIN="$PACKAGE"

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION=$(pacman -Q "$PACKAGE" | awk 'NR==1 {print $2; exit}')
echo "$VERSION" > ~/version

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME=$(wget -q https://api.github.com/repos/VHSgunzo/uruntime/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi "https.*appimage.*dwarfs.*$ARCH$" | head -1)

# Prepare AppDir
mkdir -p ./"$PACKAGE"/AppDir/shared/lib \
	./"$PACKAGE"/AppDir/usr/share/applications \
	./"$PACKAGE"/AppDir/etc
cd ./"$PACKAGE"/AppDir

cp -v /usr/share/applications/$DESKTOP              ./usr/share/applications
cp -v /usr/share/applications/$DESKTOP              ./
cp -v /usr/share/icons/hicolor/128x128/apps/"$ICON" ./
cp -v /usr/share/icons/hicolor/128x128/apps/"$ICON" ./.DirIcon

# ADD LIBRARIES
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
./lib4bin -p -v -r /usr/bin/"$TARGET_BIN"*

# DELOY QT
echo "Deploying Qt..."
mkdir -p ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/iconengines       ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/imageformats      ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/platforms         ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/platformthemes    ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/styles            ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/sqldrivers        ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/tls               ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/xcbglintegrations ./shared/lib/qt6/plugins
cp -r /usr/lib/qt6/plugins/wayland-*         ./shared/lib/qt6/plugins

# DEPLOY DEPENDENCIES OF EXTRA LIBS
echo "Deploying Qt dependencies..."
ldd ./shared/lib/qt6/plugins/*/* \
  | awk -F"[> ]" '{print $4}' | xargs -I {} cp -nv {} ./shared/lib || true

# DEPLOY GSTREAMER
echo "Deploying Gstreamer..."
cp -r /usr/lib/gstreamer-1.0  ./shared/lib
cp -nv /usr/lib/libgst*       ./shared/lib

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

# DEPLOY DEPENDENCIES OF EXTRA LIBS
echo "Deploying deps of Gstreamer..."
ldd ./shared/lib/libgst* \
	./shared/lib/gstreamer-1.0/* 2>/dev/null \
	| awk -F"[> ]" '{print $4}' | xargs -I {} cp -nv {} ./shared/lib || true

echo "Stripping libs and bins..."
find ./shared/lib ./shared/bin -type f -exec strip -s -R .comment --strip-unneeded {} ';'

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
	--compression zstd:level=22 -S22 -B16 \
	--header uruntime \
	-i ./AppDir -o "$PACKAGE"-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage

mv ./*.AppImage* ../
cd ..
rm -rf ./"$PACKAGE"
echo "All Done!"
