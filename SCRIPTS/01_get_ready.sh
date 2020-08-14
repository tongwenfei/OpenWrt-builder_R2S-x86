#!/bin/bash
set -e
# use master branch
git clone --single-branch -b nanopi-r2s https://git.openwrt.org/openwrt/staging/blocktrron.git openwrt
cd openwrt
git remote add official https://github.com/openwrt/openwrt.git && git fetch official
git rebase official/master
cd ..
# download others' source for some packages
$(which wget) --https-only --retry-connrefused https://github.com/Lienol/openwrt/archive/dev-19.07.tar.gz
tar xf dev-19.07.tar.gz
rm  -f dev-19.07.tar.gz
mv openwrt-dev-19.07 lienol-dev-19.07
exit 0
