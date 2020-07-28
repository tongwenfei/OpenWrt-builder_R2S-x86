#!/bin/bash
set -x
set -e
# master + blocktrron
git clone --single-branch -b nanopi-r2s https://github.com/blocktrron/openwrt.git openwrt
cd openwrt
git remote add openwrtupstream https://github.com/openwrt/openwrt.git
git fetch  openwrtupstream
git rebase openwrtupstream/master
cd ..
# clone others' source for some packages
$(which wget) --https-only --retry-connrefused https://github.com/Lienol/openwrt/archive/dev-19.07.tar.gz
tar xf dev-19.07.tar.gz
rm  -f dev-19.07.tar.gz
exit 0
