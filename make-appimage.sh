#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q strawberry | awk '{print $2; exit}') # example command to get version of application here
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/share/icons/hicolor/128x128/apps/strawberry.png
export DESKTOP=/usr/share/applications/org.strawberrymusicplayer.strawberry.desktop
export APPNAME=strawberry
export DEPLOY_PIPEWIRE=1
export DEPLOY_GSTREAMER=1

# Deploy dependencies
quick-sharun /usr/bin/strawberry*

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --test ./dist/*.AppImage
