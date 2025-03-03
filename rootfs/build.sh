#!/bin/bash

DIST=bookworm
BOOT_URL="https://github.com/KyonLi/ufi003-kernel/releases/download/6.6.60-1/boot.img"
BOOT_NO_MODEM_URL="https://github.com/KyonLi/ufi003-kernel/releases/download/6.6.60-1/boot-no-modem.img"
BOOT_NO_MODEM_OC_URL="https://github.com/KyonLi/ufi003-kernel/releases/download/6.6.60-1/boot-no-modem-oc.img"
K_IMAGE_DEB_URL="https://github.com/KyonLi/ufi003-kernel/releases/download/6.6.60-1/linux-image-6.6.60-msm8916-g32b5a619bbf5_6.6.60-g32b5a619bbf5-1_arm64.deb"
K_DEV_URL="https://github.com/KyonLi/ufi003-kernel/releases/tag/6.6.60-1"
UUID=a7ab80e8-e9d1-e8cd-f157-93f69b1d141e

if [ `id -u` -ne 0 ]
  then echo "Please run as root"
  exit
fi

rm -rf ../kernel/* > /dev/null 2>&1
wget -P ../kernel "$BOOT_URL"
wget -P ../kernel "$BOOT_NO_MODEM_URL"
wget -P ../kernel "$BOOT_NO_MODEM_OC_URL"
wget -P ../kernel "$K_IMAGE_DEB_URL"

mkdir debian build
debootstrap --arch=arm64 --foreign $DIST debian https://deb.debian.org/debian/
LANG=C LANGUAGE=C LC_ALL=C chroot debian /debootstrap/debootstrap --second-stage
cp ../deb-pkgs/*.deb ../kernel/linux-image-*.deb chroot.sh debian/tmp/
mv ../kernel/linux-image-*.deb debian/tmp/
mount --bind /proc debian/proc
mount --bind /dev debian/dev
mount --bind /dev/pts debian/dev/pts
mount --bind /sys debian/sys
LANG=C LANGUAGE=C LC_ALL=C chroot debian /tmp/chroot.sh
umount debian/proc
umount debian/dev/pts
umount debian/dev
umount debian/sys
cp debian/etc/debian_version ./
mv debian/tmp/info.md ./
echo >> info.md
echo "🔗 [linux-headers & linux-libc-dev]($K_DEV_URL)" >> info.md
rm -rf debian/tmp/* debian/root/.bash_history > /dev/null 2>&1

dd if=/dev/zero of=debian-ufi001c.img bs=1M count=$(( $(du -ms debian | cut -f1) + 100 ))
mkfs.ext4 -L rootfs -U $UUID debian-ufi001c.img
mount debian-ufi001c.img build
rsync -aH debian/ build/
umount build
img2simg debian-ufi001c.img rootfs.img
rm -rf debian-ufi001c.img debian build > /dev/null 2>&1
