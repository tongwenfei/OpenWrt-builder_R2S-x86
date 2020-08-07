#!/bin/bash
set -e
set -x
cp -f ./SCRIPTS/01_get_ready.sh ./01_get_ready.sh
/bin/bash ./01_get_ready.sh
cd openwrt
cp -f ../SCRIPTS/*.sh ./
/bin/bash ./02_prepare_package.sh
/bin/bash ./03_convert_translation.sh
/bin/bash ./04_remove_upx.sh
/bin/bash ./05_create_acl_for_luci.sh -a
rm -rf ./lienol-dev-19.07
cp -f ../SEED/config_no_docker.seed .config
cat   ../SEED/more.seed          >> .config
make defconfig
let make_process=$(nproc)*8
make download -j${make_process}
MY_Filter=$(mktemp)
echo '/\.git' >  ${MY_Filter}
echo '/\.svn' >> ${MY_Filter}
find ./ -maxdepth 1 | grep -v '\./$' | grep -v '/\.git' | xargs -s1024 chmod -R u=rwX,og=rX
find ./ -type f | grep -v -f ${MY_Filter} | xargs -s1024 file | grep 'executable\|ELF' | cut -d ':' -f1 | xargs -s1024 chmod 755
rm -f ${MY_Filter}
unset MY_Filter
let make_process=$(nproc)+1
make toolchain/install -j${make_process} V=s
let make_process=$(nproc)+1
make -j${make_process} V=s || make -j${make_process} V=s
cd bin/targets/rockchip/armv8
/bin/bash ../../../../../SCRIPTS/05_cleaning.sh
