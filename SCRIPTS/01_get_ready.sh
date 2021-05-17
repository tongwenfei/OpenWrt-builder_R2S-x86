#!/bin/bash
set -e
# use openwrt-21.02 branch
git clone --single-branch -b openwrt-21.02 https://git.openwrt.org/openwrt/openwrt.git openwrt
# download others' source for some packages
git clone -b main --depth=1 https://github.com/Lienol/openwrt.git          openwrt-lienol
rm -rf ./*-lienol/.git
exit 0
