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
git clone --single-branch https://github.com/coolsnowwolf/lede.git                        others_src/coolsnowwolf_lede
git clone --single-branch https://github.com/coolsnowwolf/packages.git                    others_src/coolsnowwolf_packages
git clone --single-branch https://github.com/fw876/helloworld.git                         others_src/fw876_helloworld
git clone --single-branch https://github.com/Lienol/openwrt-package.git                   others_src/Lienol_openwrt-package
git clone --single-branch https://github.com/openwrt/packages.git                         others_src/openwrt_packages
git clone --single-branch https://github.com/project-openwrt/openwrt.git                  others_src/project-openwrt_openwrt
git clone --single-branch https://github.com/vernesong/OpenClash.git                      others_src/vernesong_OpenClash
git clone --single-branch -b dev-19.07     https://github.com/Lienol/openwrt.git          others_src/Lienol_openwrt_19.07
git clone --single-branch -b openwrt-18.06 https://github.com/openwrt/luci.git            others_src/openwrt_luci_18.06
git clone --single-branch -b openwrt-19.07 https://github.com/openwrt/openwrt.git         others_src/openwrt_openwrt_19.07
git clone --single-branch -b openwrt-18.06 https://github.com/openwrt/packages.git        others_src/openwrt_packages_18.06
git clone --single-branch -b openwrt-19.07 https://github.com/project-openwrt/openwrt.git others_src/project-openwrt_openwrt_19.07
exit 0
