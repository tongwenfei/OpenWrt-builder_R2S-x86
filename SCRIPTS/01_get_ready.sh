#!/bin/bash
set -e
# use master branch
git clone --single-branch -b master https://git.openwrt.org/openwrt/openwrt.git openwrt
# download others' source for some packages
git clone -b main --depth 1 https://github.com/Lienol/openwrt.git      openwrt-lienol
git clone -b main --depth 1 https://github.com/Lienol/openwrt-packages packages-lienol
git clone -b main --depth 1 https://github.com/Lienol/openwrt-luci     luci-lienol
rm -rf ./*-lienol/.git
exit 0
