#!/bin/bash
set -e
# use master branch
git clone --single-branch -b master https://git.openwrt.org/openwrt/openwrt.git openwrt
# download others' source for some packages
$(which wget) --https-only --retry-connrefused https://github.com/Lienol/openwrt/archive/19.07.tar.gz
tar xf 19.07.tar.gz
rm  -f 19.07.tar.gz
mv openwrt-19.07 lienol-19.07
exit 0
