#!/bin/bash
set -x
set -e
alias wget="$(which wget) --https-only --retry-connrefused"

### 1. 准备工作 ###
# blocktrron.git 
patch -p1 < ../PATCH/new/main/exp/uboot-rockchip-update-to-v2020.10.patch
# 使用19.07的feed源
rm -f ./feeds.conf.default
wget            https://raw.githubusercontent.com/openwrt/openwrt/openwrt-19.07/feeds.conf.default
wget -P include https://raw.githubusercontent.com/openwrt/openwrt/openwrt-19.07/include/scons.mk
# 添加UPX支持，以完善v2ray等组件的编译
patch -p1 < ../PATCH/new/main/0001-tools-add-upx-ucl-support.patch || true
# remove annoying snapshot tag
sed -i "s,SNAPSHOT,$(date '+%Y.%m.%d'),g"  include/version.mk
sed -i "s,snapshots,$(date '+%Y.%m.%d'),g" package/base-files/image-config.in
# 使用O2级别的优化
sed -i 's/-Os/-O2/g' include/target.mk
# 更新feed
./scripts/feeds update -a && ./scripts/feeds install -a

### 2. 替换语言支持 ###
# 更换GCC版本
rm -rf ./feeds/packages/devel/gcc
svn co https://github.com/openwrt/packages/trunk/devel/gcc   feeds/packages/devel/gcc
#更换Golang版本
rm -rf ./feeds/packages/lang/golang ./feeds/packages/devel/packr
svn co https://github.com/openwrt/packages/trunk/lang/golang feeds/packages/lang/golang
svn co https://github.com/openwrt/packages/trunk/devel/packr feeds/packages/devel/packr
ln -sf ../../../feeds/packages/devel/packr ./package/feeds/packages/packr
# 更换Node.js版本
rm -rf ./feeds/packages/lang/node
svn co https://github.com/openwrt/packages/trunk/lang/node   feeds/packages/lang/node
# 修复Python编译报错
pushd feeds/packages
patch -p1 < ../../../PATCH/0001-python3-fix-compilation.patch
popd

### 3. 必要的Patch ###
# 重要：补充curl包
rm -rf ./package/network/utils/curl
svn co https://github.com/openwrt/packages/trunk/net/curl    package/network/utils/curl
# 更换htop
rm -rf ./feeds/packages/admin/htop
svn co https://github.com/openwrt/packages/trunk/admin/htop  feeds/packages/admin/htop
# 补充lzo
rm -rf ./package/libs/lzo ./feeds/packages/libs/lzo
svn co https://github.com/openwrt/packages/trunk/libs/lzo    feeds/packages/libs/lzo
ln -sdf ../../../feeds/packages/libs/lzo ./package/feeds/packages/lzo
# 补充iftop
rm -rf ./package/network/utils/iftop ./feeds/packages/net/iftop
svn co https://github.com/openwrt/packages/trunk/net/iftop   feeds/packages/net/iftop
ln -sdf ../../../feeds/packages/net/iftop ./package/feeds/packages/iftop
# 更换libcap
rm -rf ./feeds/packages/libs/libcap/
svn co https://github.com/openwrt/packages/trunk/libs/libcap feeds/packages/libs/libcap
# 更换cryptodev-linux
rm -rf ./package/kernel/cryptodev-linux
svn co https://github.com/project-openwrt/openwrt/branches/master/package/kernel/cryptodev-linux package/kernel/cryptodev-linux
# 3328 add idle
wget -P target/linux/rockchip/patches-5.4 https://github.com/project-openwrt/openwrt/raw/master/target/linux/rockchip/patches-5.4/005-arm64-dts-rockchip-Add-RK3328-idle-state.patch
# IRQ
sed -i '/set_interface_core 4 "eth1"/a\set_interface_core 8 "ff160000" "ff160000.i2c"' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
sed -i '/set_interface_core 4 "eth1"/a\set_interface_core 1 "ff150000" "ff150000.i2c"' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
# disabed rk3328 ethernet tcp/udp offloading tx/rx
sed -i '/;;/i\ethtool -K eth0 rx off tx off && logger -t disable-offloading "disabed rk3328 ethernet tcp/udp offloading tx/rx"' target/linux/rockchip/armv8/base-files/etc/hotplug.d/net/40-net-smp-affinity
# Patch i2c0
cp -f ../PATCH/new/main/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch ./target/linux/rockchip/patches-5.4/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch
# OC 1.5GHz
cp -f ../PATCH/999-RK3328-enable-1512mhz-opp.patch ./target/linux/rockchip/patches-5.4/999-RK3328-enable-1512mhz-opp.patch
# swap LAN WAN
patch -p1 < ../PATCH/swap-LAN-WAN.patch
# luci network
patch -p1 < ../PATCH/new/main/luci_network-add-packet-steering.patch
# Patch jsonc
patch -p1 < ../PATCH/new/package/use_json_object_new_int64.patch
# Patch dnsmasq filter AAAA
patch -p1 < ../PATCH/new/package/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/new/package/luci-add-filter-aaaa-option.patch
cp  -f      ../PATCH/new/package/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
rm -rf ./package/base-files/files/etc/init.d/boot
wget  -P package/base-files/files/etc/init.d/ https://raw.githubusercontent.com/project-openwrt/openwrt/openwrt-18.06-k5.4/package/base-files/files/etc/init.d/boot
# Patch Kernel 以解决FullCone冲突
pushd target/linux/generic/hack-5.4
wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd
# Patch FireWall 以增添FullCone功能
mkdir -p package/network/config/firewall/patches
wget  -P package/network/config/firewall/patches https://raw.githubusercontent.com/LGA1150/fullconenat-fw3-patch/master/fullconenat.patch
# Patch LuCI 以增添FullCone开关
pushd feeds/luci
wget -qO - https://raw.githubusercontent.com/LGA1150/fullconenat-fw3-patch/master/luci.patch | patch -p1
popd
# FullCone 相关组件
cp -rf ../openwrt-lienol/package/network/fullconenat ./package/network/fullconenat
# Patch Kernel 以支持SFE
pushd target/linux/generic/hack-5.4
wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
popd
# Patch LuCI 以增添SFE开关
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_sfe_switch.patch
# SFE 相关组件
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe     package/lean/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/lean/fast-classifier
cp -f ../PATCH/duplicate/shortcut-fe ./package/base-files/files/etc/init.d/
# 修复由于shadow-utils引起的管理页面修改密码功能失效的问题
pushd feeds/luci
patch -p1 < ../../../PATCH/let-luci-use-busybox-passwd.patch
popd

### 4. 更新部分软件包 ###
mkdir -p ./package/new/ ./package/lean/
# AdGuard
cp -rf ../openwrt-lienol/package/diy/luci-app-adguardhome ./package/new/luci-app-adguardhome
svn co https://github.com/openwrt/packages/trunk/net/adguardhome feeds/packages/net/adguardhome
ln -sf ../../../feeds/packages/net/adguardhome ./package/feeds/packages/adguardhome
sed -i '/init/d' feeds/packages/net/adguardhome/Makefile
# arpbind
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-arpbind         package/lean/luci-app-arpbind
# AutoCore
svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/autocore package/lean/autocore
pushd package/lean/autocore
patch -p1 < ../../../../PATCH/autocore-luci-use-busybox-passwd.patch
popd
svn co https://github.com/project-openwrt/packages/trunk/utils/coremark                 feeds/packages/utils/coremark
sed -i 's,default n,default y,g' feeds/packages/utils/coremark/Makefile
ln -sdf ../../../feeds/packages/utils/coremark ./package/feeds/packages/coremark
# AutoReboot定时重启
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot      package/lean/luci-app-autoreboot
# ChinaDNS
git clone -b luci   --depth 1 https://github.com/pexcn/openwrt-chinadns-ng.git          package/new/luci-app-chinadns-ng
git clone -b master --depth 1 https://github.com/pexcn/openwrt-chinadns-ng.git          package/new/chinadns-ng
cp -f ../PATCH/new/script/chinadnslist package/new/chinadns-ng/update-list.sh
pushd package/new/chinadns-ng
sed -i 's,/etc/chinadns-ng,files,g' ./update-list.sh
/bin/bash ./update-list.sh
popd
# luci-app-cpulimit
cp -rf ../PATCH/duplicate/luci-app-cpulimit                                             ./package/lean/luci-app-cpulimit
svn co https://github.com/project-openwrt/openwrt/branches/master/package/ntlf9t/cpulimit package/lean/cpulimit
# SmartDNS
cp -rf ../packages-lienol/net/smartdns                  ./package/new/smartdns
cp -rf ../luci-lienol/applications/luci-app-smartdns    ./package/new/luci-app-smartdns
sed -i 's,include ../..,include $(TOPDIR)/feeds/luci,g' ./package/new/luci-app-smartdns/Makefile
# DDNS
rm -rf ./feeds/packages/net/ddns-scripts ./feeds/luci/applications/luci-app-ddns
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_aliyun       package/lean/ddns-scripts_aliyun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_dnspod       package/lean/ddns-scripts_dnspod
svn co https://github.com/openwrt/packages/branches/openwrt-18.06/net/ddns-scripts       feeds/packages/net/ddns-scripts
svn co https://github.com/openwrt/luci/branches/openwrt-18.06/applications/luci-app-ddns feeds/luci/applications/luci-app-ddns
# 清理内存
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree        package/lean/luci-app-ramfree
# 流量监视
git clone -b master --depth 1 https://github.com/brvphoenix/wrtbwmon                   package/new/wrtbwmon
git clone -b master --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon          package/new/luci-app-wrtbwmon
# SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus                     package/lean/luci-app-ssr-plus
# PASSWALL
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/luci-app-passwall           package/new/luci-app-passwall
# OpenClash
git clone -b master --depth 1 https://github.com/vernesong/OpenClash                   package/new/luci-app-openclash
# SSRP依赖
rm -rf ./feeds/packages/net/kcptun ./feeds/packages/net/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shadowsocksr-libev      package/lean/shadowsocksr-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt               package/lean/pdnsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/kcptun                  package/lean/kcptun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/srelay                  package/lean/srelay
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks              package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks               package/lean/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2               package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/proxychains-ng          package/lean/proxychains-ng
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks               package/lean/ipt2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs             package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev            package/lean/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan                  package/lean/trojan
svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/tcpping package/lean/tcpping
svn co https://github.com/fw876/helloworld/trunk/naiveproxy                            package/lean/naiveproxy
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/tcping                      package/new/tcping
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-go                   package/new/trojan-go
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/brook                       package/new/brook
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-plus                 package/new/trojan-plus
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/ssocks                      package/new/ssocks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/v2ray                       package/new/v2ray
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/v2ray-plugin                package/new/v2ray-plugin
# xary (xtls support)
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/xray                        package/new/xray
sed -i 's,default n,default y,g'            package/new/xray/Makefile
# PASSWALL modification
sed -i 's,default n,default y,g'            package/new/luci-app-passwall/Makefile
sed -i '/V2ray:v2ray/d'                     package/new/luci-app-passwall/Makefile
sed -i '/https_dns_proxy:https-dns-proxy/d' package/new/luci-app-passwall/Makefile
sed -i 's,ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA,ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256,g' package/new/luci-app-passwall/luasrc/model/cbi/passwall/server/api/trojan.lua
sed -i 's,TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256,g' package/new/luci-app-passwall/luasrc/model/cbi/passwall/server/api/trojan.lua
# SSRP modification
sed -i 's,default n,default y,g'            package/lean/luci-app-ssr-plus/Makefile
sed -i '/V2ray:v2ray/d'                     package/lean/luci-app-ssr-plus/Makefile
sed -i 's,ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA,ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256,g' package/lean/luci-app-ssr-plus/root/usr/share/shadowsocksr/gentrojanconfig.lua
sed -i 's,TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256,g' package/lean/luci-app-ssr-plus/root/usr/share/shadowsocksr/gentrojanconfig.lua
# 订阅转换
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/subconverter package/new/subconverter
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/jpcre2       package/new/jpcre2
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/rapidjson    package/new/rapidjson
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/duktape      package/new/duktape
# ipv6-helper
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipv6-helper                           package/lean/ipv6-helper
# Zerotier
svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/luci-app-zerotier     package/lean/luci-app-zerotier
rm -rf ./feeds/packages/net/zerotier/files/etc/init.d/zerotier
# argon主题
git clone -b master --depth 1 https://github.com/jerrykuku/luci-theme-argon        package/new/luci-theme-argon
git clone -b master --depth 1 https://github.com/jerrykuku/luci-app-argon-config   package/new/luci-app-argon-config
# edge主题
git clone -b master --depth 1 https://github.com/garypang13/luci-theme-edge        package/new/luci-theme-edge
# vim
rm -rf ./feeds/packages/utils/vim
svn co https://github.com/openwrt/packages/trunk/utils/vim                         feeds/packages/utils/vim
# stress-ng
svn co https://github.com/openwrt/packages/trunk/utils/stress-ng                   feeds/packages/utils/stress-ng
# 补全部分依赖（实际上并不会用到）
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libconfig              package/libs/libconfig
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-cthelper  package/libs/libnetfilter-cthelper
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-cttimeout package/libs/libnetfilter-cttimeout
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-log       package/libs/libnetfilter-log
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libnetfilter-queue     package/libs/libnetfilter-queue
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libusb-compat          package/libs/libusb-compat
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/utils/fuse                  package/utils/fuse
rm -rf ./feeds/packages/utils/lvm2
svn co https://github.com/openwrt/packages/trunk/utils/lvm2                        feeds/packages/utils/lvm2
rm -rf ./feeds/packages/utils/collectd
svn co https://github.com/openwrt/packages/trunk/utils/collectd                    feeds/packages/utils/collectd
svn co https://github.com/openwrt/packages/trunk/utils/hwdata                      feeds/packages/utils/hwdata
ln -sf ../../../feeds/packages/utils/hwdata    ./package/feeds/packages/hwdata
svn co https://github.com/openwrt/packages/trunk/libs/nghttp2                      feeds/packages/libs/nghttp2
ln -sdf ../../../feeds/packages/libs/nghttp2   ./package/feeds/packages/nghttp2
svn co https://github.com/openwrt/packages/trunk/libs/libcap-ng                    feeds/packages/libs/libcap-ng
ln -sdf ../../../feeds/packages/libs/libcap-ng ./package/feeds/packages/libcap-ng
# 翻译及部分功能优化
cp -rf ../PATCH/duplicate/addition-trans-zh-master ./package/lean/lean-translate
# 给root用户添加vim和screen的配置文件
mkdir -p                      package/base-files/files/root
cp -f ../PRECONFS/vimrc       package/base-files/files/root/.vimrc
cp -f ../PRECONFS/screenrc    package/base-files/files/root/.screenrc

### 5. 最后的收尾工作 ###
mkdir -p                               package/base-files/files/usr/bin
cp -f ../PATCH/new/script/chinadnslist package/base-files/files/usr/bin/update-chinadns-list
# 最大连接
sed -i 's/16384/65536/g'               package/kernel/linux/files/sysctl-nf-conntrack.conf
# crypto相关
echo '
CONFIG_ARM64_CRYPTO=y
CONFIG_CRYPTO_AES_ARM64=y
CONFIG_CRYPTO_AES_ARM64_BS=y
CONFIG_CRYPTO_AES_ARM64_CE=y
CONFIG_CRYPTO_AES_ARM64_CE_BLK=y
CONFIG_CRYPTO_AES_ARM64_CE_CCM=y
CONFIG_CRYPTO_AES_ARM64_NEON_BLK=y
CONFIG_CRYPTO_CHACHA20=y
CONFIG_CRYPTO_CHACHA20_NEON=y
CONFIG_CRYPTO_CRYPTD=y
CONFIG_CRYPTO_GF128MUL=y
CONFIG_CRYPTO_GHASH_ARM64_CE=y
CONFIG_CRYPTO_SHA1=y
CONFIG_CRYPTO_SHA1_ARM64_CE=y
CONFIG_CRYPTO_SHA256_ARM64=y
CONFIG_CRYPTO_SHA2_ARM64_CE=y
# CONFIG_CRYPTO_SHA3_ARM64 is not set
CONFIG_CRYPTO_SHA512_ARM64=y
# CONFIG_CRYPTO_SHA512_ARM64_CE is not set
CONFIG_CRYPTO_SIMD=y
# CONFIG_CRYPTO_SM3_ARM64_CE is not set
# CONFIG_CRYPTO_SM4_ARM64_CE is not set
' >> ./target/linux/rockchip/armv8/config-5.4
# 删除已有配置
rm -rf .config
# 删除.svn目录
find ./ -type d -name '.svn' -print0 | xargs -0 -s1024 /bin/rm -rf
unalias wget
exit 0
