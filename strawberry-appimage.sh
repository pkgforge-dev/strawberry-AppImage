#!/bin/sh

set -eu

PACKAGE=strawberry
DESKTOP=org.strawberrymusicplayer.strawberry.desktop
ICON=strawberry.png
TARGET_BIN="$PACKAGE"

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION=$(pacman -Q $PACKAGE | awk 'NR==1 {print $2; exit}')

APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|continuous|*$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

# Prepare AppDir
mkdir -p ./"$PACKAGE"/AppDir/shared/lib \
	./"$PACKAGE"/AppDir/usr/share/applications \
	./"$PACKAGE"/AppDir/etc
cd ./"$PACKAGE"/AppDir

cp /usr/share/applications/$DESKTOP              ./usr/share/applications
cp /usr/share/applications/$DESKTOP              ./
cp /usr/share/icons/hicolor/128x128/apps/"$ICON" ./

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
echo "Patching Gstreamer bins..."
rm -f ./shared/lib/gstreamer-1.0/gst-plugins-doc-cache-generator || true
rm -f ./shared/lib/gstreamer-1.0/libgstopengl* || true
patchelf --set-interpreter "./shared/lib/ld-linux-x86-64.so.2" ./shared/lib/gstreamer-1.0/gst-*

# DEPLOY DEPENDENCIES OF EXTRA LIBS
echo "Deploying deps of Gstreamer..."
ldd ./shared/lib/libgst* \
	./shared/lib/gstreamer-1.0/* 2>/dev/null \
  | awk -F"[> ]" '{print $4}' | xargs -I {} cp -nv {} ./shared/lib || true

echo "Stripping libs and bins..."
find ./shared/lib ./shared/bin -type f -exec strip -s -R .comment --strip-unneeded {} ';'

# Prepare sharun
echo "Preparing sharun..."
echo 'SHARUN_WORKING_DIR="${SHARUN_DIR}"
LD_LIBRARY_PATH="${SHARUN_DIR}/shared/lib:${SHARUN_DIR}/shared/lib/pulseaudio:${LD_LIBRARY_PATH}"' > ./.env
ln ./sharun ./AppRun
./sharun -g

# Remove bloats
echo "Removing bloats..."
rm -f ./shared/lib/libLLVM* ./shared/lib/libgallium* || true

# MAKE APPIAMGE WITH FUSE3 COMPATIBLE APPIMAGETOOL
cd ..
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n -u "$UPINFO" "$PWD"/AppDir "$PWD"/"$PACKAGE"-"$VERSION"-"$ARCH".AppImage

mv ./*.AppImage* ../
cd ..
rm -rf ./"$PACKAGE"
echo "All Done!"
