#!/bin/bash
set -e

echo "Start            $(date)" | tee buildtime.txt
git clone --single-branch -b master https://github.com/KaneGreen/OpenWrt-builder_R2S-x86.git
cd OpenWrt-builder_R2S-x86

echo "Clone Openwrt    $(date)" | tee -a ../buildtime.txt
cp -f ./SCRIPTS/01_get_ready.sh ./01_get_ready.sh
/bin/bash ./01_get_ready.sh
cd openwrt

echo "Prepare Package  $(date)" | tee -a ../../buildtime.txt
cp -f ../SCRIPTS/*.sh ./
/bin/bash ./02_prepare_package.sh

echo "Modification     $(date)" | tee -a ../../buildtime.txt
/bin/bash ./03_convert_translation.sh
/bin/bash ./04_remove_upx.sh
/bin/bash ./05_create_acl_for_luci.sh -a

echo "Make Defconfig   $(date)" | tee -a ../../buildtime.txt
[ -f "../SEED/${MYOPENWRTTARGET}.config.seed" ] || MYOPENWRTTARGET='R2S'
cp -f "../SEED/${MYOPENWRTTARGET}.config.seed" .config
cat ../SEED/more.seed >> .config
make defconfig

echo "Make Download    $(date)" | tee -a ../../buildtime.txt
make download -j8

echo "Smart Chmod      $(date)" | tee -a ../../buildtime.txt
cd ..
MY_Filter=$(mktemp)
echo '/\.git' >  "${MY_Filter}"
echo '/\.svn' >> "${MY_Filter}"
find ./ -maxdepth 1 | grep -v '\./$' | grep -v '/\.git' | xargs -s1024 chmod -R u=rwX,og=rX
find ./ -type f | grep -v -f "${MY_Filter}" | xargs -s1024 file | grep 'executable\|ELF' | cut -d ':' -f1 | xargs -s1024 chmod 755
rm -f "${MY_Filter}"
unset MY_Filter
cd openwrt

echo "Make Toolchain   $(date)" | tee -a ../../buildtime.txt
make toolchain/install -j16

echo "Compile Openwrt  $(date)" | tee -a ../../buildtime.txt
[[ ${Make_Process} =~ ^[0-9]+$ ]] && Make_Process=4
make -j${Make_Process} V=w

cd ../..
echo "Finished         $(date)" | tee -a buildtime.txt

