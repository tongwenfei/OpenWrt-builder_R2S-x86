#!/bin/bash
set -e
# use master branch
git clone --single-branch -b master https://git.openwrt.org/openwrt/openwrt.git openwrt
# download others' source for some packages
git clone --single-branch https://github.com/Lienol/openwrt.git      openwrt-lienol
git clone --single-branch https://github.com/Lienol/openwrt-packages packages-lienol
git clone --single-branch https://github.com/Lienol/openwrt-luci     luci-lienol
exit 0
