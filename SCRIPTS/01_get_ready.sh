#!/bin/bash
set -x
git clone --single-branch -b nanopi-r2s https://git.openwrt.org/openwrt/staging/blocktrron.git openwrt
cd openwrt
git remote add openwrtupstream https://github.com/openwrt/openwrt.git && git fetch openwrtupstream
git rebase openwrtupstream/master
# 交换LAN/WAN
git apply ../PATCH/swap-LAN-WAN.patch
# 启用温度显示
sed -i 's/# CONFIG_ROCKCHIP_THERMAL is not set/CONFIG_ROCKCHIP_THERMAL=y/g' target/linux/rockchip/armv8/config-5.4
cd ..
exit 0
