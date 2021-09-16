#!/bin/bash
set -e
alias wget="$(which wget) --https-only --retry-connrefused"

# get the latest release version of 21.02
LATESTRELEASE=$(curl -sSf -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/openwrt/openwrt/tags | jq '.[].name' | grep -v 'rc' | grep 'v21' | sort -r | head -n 1)
LATESTRELEASE=${LATESTRELEASE:1:-1}

wget https://github.com/openwrt/openwrt/archive/${LATESTRELEASE}.tar.gz

mkdir openwrt_release

tar xf ${LATESTRELEASE}.tar.gz --strip-components=1 --directory=./openwrt_release
rm  -f ${LATESTRELEASE}.tar.gz

git clone --single-branch -b openwrt-21.02 https://github.com/openwrt/openwrt.git openwrt_new
rm  -f ./openwrt_new/include/version.mk
rm  -f ./openwrt_new/include/kernel-version.mk
rm  -f ./openwrt_new/package/base-files/image-config.in
rm -rf ./openwrt_new/target/linux/

cp  -f ./openwrt_release/include/version.mk                 ./openwrt_new/include/version.mk
cp  -f ./openwrt_release/include/kernel-version.mk          ./openwrt_new/include/kernel-version.mk
cp  -f ./openwrt_release/package/base-files/image-config.in ./openwrt_new/package/base-files/image-config.in
cp -rf ./openwrt_release/target/linux/                      ./openwrt_new/target/linux/

mv ./openwrt_new/ ./openwrt/
rm -rf ./openwrt_release/

unalias wget
exit 0
