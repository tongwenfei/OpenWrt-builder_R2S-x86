#!/bin/bash
set -e
# use master branch
git clone --single-branch -b master https://git.openwrt.org/openwrt/openwrt.git openwrt
# download others' source for some packages
$(which wget) --https-only --retry-connrefused https://github.com/Lienol/openwrt/archive/dev-19.07.tar.gz
tar xf dev-19.07.tar.gz
rm  -f dev-19.07.tar.gz
exit 0
