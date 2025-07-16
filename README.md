# strawberry-AppImage 🐧

[![GitHub Downloads](https://img.shields.io/github/downloads/pkgforge-dev/strawberry-AppImage/total?logo=github&label=GitHub%20Downloads)](https://github.com/pkgforge-dev/strawberry-AppImage/releases/latest)
[![CI Build Status](https://github.com//pkgforge-dev/strawberry-AppImage/actions/workflows/blank.yml/badge.svg)](https://github.com/pkgforge-dev/strawberry-AppImage/releases/latest)

Made it since the creator removed the original one [and wants 200 usd per month to give it back?!](https://forum.strawberrymusicplayer.org/topic/1094/appimages-for-linux)

* [Latest Stable Release](https://github.com/pkgforge-dev/strawberry-AppImage/releases/latest)

---

AppImage made using [sharun](https://github.com/VHSgunzo/sharun), which makes it extremely easy to turn any binary into a portable package without using containers or similar tricks.

**This AppImage bundles everything and should work on any linux distro, even on musl based ones.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i strawberry` or `appman -i strawberry`

* [dbin](https://github.com/xplshn/dbin) `dbin install strawberry.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install strawberry`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)

<details>
  <summary><b><i>raison d'être</i></b></summary>
    <img src="https://github.com/user-attachments/assets/d40067a6-37d2-4784-927c-2c7f7cc6104b" alt="Inspiration Image">
  </a>
</details>

---

More at: [AnyLinux-AppImages](https://pkgforge-dev.github.io/Anylinux-AppImages/) 
