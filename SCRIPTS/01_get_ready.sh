#!/bin/bash
set -x
set -e
# master + jayanta525
git clone --single-branch -b master https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt
patch -p1 < ../PATCH/jayanta525/001-rockchip-add-support-for-rk3328-radxa-rock-pi-e.patch
patch -p1 < ../PATCH/jayanta525/002-rockchip-add-support-for-FriendlyARM-NanoPi-R2S.patch
cd ..
# clone others' source for some packages
$(which wget) --https-only --retry-connrefused https://github.com/Lienol/openwrt/archive/dev-19.07.tar.gz
tar xf dev-19.07.tar.gz
rm  -f dev-19.07.tar.gz
exit 0
