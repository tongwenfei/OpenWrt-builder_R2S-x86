#!/bin/bash
set -x
git clone --single-branch -b master https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt
patch -p1 < ../PATCH/jayanta525/001-rockchip-add-support-for-rk3328-radxa-rock-pi-e.patch
patch -p1 < ../PATCH/jayanta525/002-rockchip-add-support-for-FriendlyARM-NanoPi-R2S.patch
# 交换LAN/WAN
git apply ../PATCH/swap-LAN-WAN.patch
# 启用温度显示
sed -i 's/# CONFIG_ROCKCHIP_THERMAL is not set/CONFIG_ROCKCHIP_THERMAL=y/g' target/linux/rockchip/armv8/config-5.4
cd ..
# clone others' source for some packages
mkdir -p others_src
git clone --single-branch -b dev-19.07 https://github.com/Lienol/openwrt.git others_src/Lienol_openwrt_19.07
exit 0
