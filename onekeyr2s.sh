#!/bin/bash
cp -f ./SCRIPTS/01_get_ready.sh ./01_get_ready.sh
/bin/bash ./01_get_ready.sh
cd openwrt
cp -f ../SCRIPTS/*.sh ./
/bin/bash ./02_prepare_package.sh
/bin/bash ./03_convert_translation.sh
/bin/bash ./04_remove_upx.sh
cp -f ../SEED/config_2.seed .config
cat   ../SEED/more.seed  >> .config
make defconfig
let make_process=$(nproc)*8
make download -j${make_process}
chmod -R u=rwX,og=rX ./
find ./ -type f -print0 | xargs -s1024 -0 file | grep 'executable\|ELF' | cut -d ':' -f1 | xargs -s1024 chmod 755
let make_process=$(nproc)+1
make toolchain/install -j${make_process} V=s
let make_process=$(nproc)+1
make -j${make_process} V=s || make -j${make_process} V=s
cd bin/targets/rockchip/armv8
/bin/bash ../../../../../SCRIPTS/05_cleaning.sh
