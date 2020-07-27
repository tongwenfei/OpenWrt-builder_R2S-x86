#!/bin/bash
set -x
set -e
alias wget="$(which wget) --https-only --retry-connrefused"

### 1. 准备工作 ###
# 使用19.07的feed源
rm -f ./feeds.conf.default
wget            https://raw.githubusercontent.com/openwrt/openwrt/openwrt-19.07/feeds.conf.default
wget -P include https://raw.githubusercontent.com/openwrt/openwrt/openwrt-19.07/include/scons.mk
# remove annoying snapshot tag
sed -i "s,SNAPSHOT,$(date '+%Y.%m.%d'),g"  include/version.mk
sed -i "s,snapshots,$(date '+%Y.%m.%d'),g" package/base-files/image-config.in
# 使用O3级别的优化
sed -i 's/Os/O3/g' include/target.mk
sed -i 's/O2/O3/g' ./rules.mk
# 更新feed
./scripts/feeds update -a && ./scripts/feeds install -a

### 2. 替换语言支持 ###
# 更换Node.js版本
rm -rf ./feeds/packages/lang/node
svn co https://github.com/openwrt/packages/trunk/lang/node   feeds/packages/lang/node
# 更换GCC版本
rm -rf ./feeds/packages/devel/gcc
svn co https://github.com/openwrt/packages/trunk/devel/gcc   feeds/packages/devel/gcc
# 更换Golang版本
rm -rf ./feeds/packages/lang/golang
svn co https://github.com/openwrt/packages/trunk/lang/golang feeds/packages/lang/golang

### 3. 必要的Patch ###
# irqbalance
sed -i 's/0/1/g' feeds/packages/utils/irqbalance/files/irqbalance.config
# Patch rk-crypto
patch -p1 < ../PATCH/kernel_crypto-add-rk3328-crypto-support.patch
# Patch jsonc
patch -p1 < ../PATCH/use_json_object_new_int64.patch
# dnsmasq filter AAAA
patch -p1 < ../PATCH/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/luci-add-filter-aaaa-option.patch
cp -f ../PATCH/900-add-filter-aaaa-option.patch    ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
rm -rf ./package/base-files/files/etc/init.d/boot
wget -P  package/base-files/files/etc/init.d https://raw.githubusercontent.com/project-openwrt/openwrt/18.06-kernel5.4/package/base-files/files/etc/init.d/boot
# Patch FireWall 以增添fullcone功能
mkdir -p package/network/config/firewall/patches
wget  -P package/network/config/firewall/patches https://raw.githubusercontent.com/LGA1150/fullconenat-fw3-patch/master/fullconenat.patch
# Patch LuCI 以增添fullcone开关
pushd feeds/luci
wget -qO - https://raw.githubusercontent.com/LGA1150/fullconenat-fw3-patch/master/luci.patch | git apply
popd
# Patch Kernel 以解决fullcone冲突
pushd target/linux/generic/hack-5.4
wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd
# FullCone模块
git clone -b master --single-branch https://github.com/QiuSimons/openwrt-fullconenat package/fullconenat
# Patch FireWall 以增添SFE
patch -p1 < ../PATCH/luci-app-firewall_add_sfe_switch.patch
# SFE内核补丁
pushd target/linux/generic/hack-5.4
wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/999-shortcut-fe-support.patch
popd
# SFE
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe     package/new/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/new/fast-classifier
# OC 1.5GHz
cp -f ../PATCH/999-RK3328-enable-1512mhz-opp.patch ./target/linux/rockchip/patches-5.4/999-RK3328-enable-1512mhz-opp.patch

### 4. 更新部分软件包 ###
# AdGuard
cp -rf ../openwrt-dev-19.07/package/diy/luci-app-adguardhome              package/new/luci-app-adguardhome
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ntlf9t/AdGuardHome package/new/AdGuardHome
# arpbind
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-arpbind         package/lean/luci-app-arpbind
# AutoCore
svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/autocore package/lean/autocore
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/coremark                 package/lean/coremark
sed -i 's,-DMULTIT,-Ofast -DMULTIT,g' package/lean/coremark/Makefile
# AutoReboot定时重启
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot      package/lean/luci-app-autoreboot
# ChinaDNS
git clone -b luci   --single-branch https://github.com/pexcn/openwrt-chinadns-ng        package/new/luci-chinadns-ng
git clone -b master --single-branch https://github.com/pexcn/openwrt-chinadns-ng        package/new/chinadns-ng
cp -f ../PATCH/chinadnslist package/new/chinadns-ng/update-list.sh
pushd package/new/chinadns-ng
sed -i 's,/etc/chinadns-ng,files,g' ./update-list.sh
/bin/bash ./update-list.sh
popd
# DDNS
rm -rf ./feeds/packages/net/ddns-scripts ./feeds/luci/applications/luci-app-ddns
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_aliyun       package/lean/ddns-scripts_aliyun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_dnspod       package/lean/ddns-scripts_dnspod
svn co https://github.com/openwrt/packages/branches/openwrt-18.06/net/ddns-scripts       feeds/packages/net/ddns-scripts
svn co https://github.com/openwrt/luci/branches/openwrt-18.06/applications/luci-app-ddns feeds/luci/applications/luci-app-ddns
# 状态监控
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-netdata          package/lean/luci-app-netdata
# 清理内存
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree          package/lean/luci-app-ramfree
# 流量监视
git clone -b master --single-branch https://github.com/brvphoenix/wrtbwmon               package/new/wrtbwmon
git clone -b master --single-branch https://github.com/brvphoenix/luci-app-wrtbwmon      package/new/luci-app-wrtbwmon
# SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus                       package/lean/luci-app-ssr-plus
cp -f  ../REPLACE/ssrurl.htm package/lean/luci-app-ssr-plus/luasrc/view/shadowsocksr/ssrurl.htm
# SSRP依赖
rm -rf ./feeds/packages/net/kcptun ./feeds/packages/net/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shadowsocksr-libev package/lean/shadowsocksr-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt          package/lean/pdnsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray              package/lean/v2ray
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/kcptun             package/lean/kcptun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray-plugin       package/lean/v2ray-plugin
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/srelay             package/lean/srelay
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks         package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks          package/lean/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2          package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/proxychains-ng     package/lean/proxychains-ng
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks          package/lean/ipt2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs        package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev       package/lean/shadowsocks-libev
svn co https://github.com/project-openwrt/openwrt/trunk/package/lean/tcpping      package/lean/tcpping
# PASSWALL
svn co https://github.com/Lienol/openwrt-package/trunk/lienol/luci-app-passwall   package/new/luci-app-passwall
svn co https://github.com/Lienol/openwrt-package/trunk/package/tcping             package/new/tcping
svn co https://github.com/Lienol/openwrt-package/trunk/package/trojan-go          package/new/trojan-go
svn co https://github.com/Lienol/openwrt-package/trunk/package/brook              package/new/brook
svn co https://github.com/Lienol/openwrt-package/trunk/package/trojan             package/new/trojan
# OpenClash
svn co https://github.com/vernesong/OpenClash/branches/master/luci-app-openclash  package/new/luci-app-openclash
# 订阅转换
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/subconverter package/new/subconverter
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/jpcre2       package/new/jpcre2
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/rapidjson    package/new/rapidjson
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/duktape      package/new/duktape
# Zerotier
git clone https://github.com/rufengsuixing/luci-app-zerotier                            package/lean/luci-app-zerotier
svn co https://github.com/coolsnowwolf/packages/trunk/net/zerotier                      package/lean/zerotier
# CF811AC wifi driver
svn co https://github.com/project-openwrt/openwrt/trunk/package/ctcgfw/rtl8821cu        package/ctcgfw/rtl8821cu
# argon主题
git clone -b master --single-branch https://github.com/jerrykuku/luci-theme-argon       package/new/luci-theme-argon
# edge主题
git clone -b master --single-branch https://github.com/garypang13/luci-theme-edge       package/new/luci-theme-edge
# 补全部分依赖（实际上并不会用到）
rm -rf ./feeds/packages/utils/collectd
svn co https://github.com/openwrt/packages/trunk/utils/collectd                         feeds/packages/utils/collectd
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/utils/fuse     package/utils/fuse
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libconfig package/libs/libconfig
# 翻译及部分功能优化
git clone -b master --single-branch https://github.com/QiuSimons/addition-trans-zh      package/lean/lean-translate
cp -f ../REPLACE/zzz-default-settings package/lean/lean-translate/files/zzz-default-settings
# 给root用户添加vim和screen的配置文件
mkdir -p                      package/base-files/files/root
cp -f ../PRECONFS/vimrc       package/base-files/files/root/.vimrc
cp -f ../PRECONFS/screenrc    package/base-files/files/root/.screenrc

### 5. 最后的收尾工作 ###
mkdir -p                      package/base-files/files/usr/bin
cp -f ../PATCH/chinadnslist   package/base-files/files/usr/bin/update-chinadns-list
# 最大连接
sed -i 's/16384/65536/g'      package/kernel/linux/files/sysctl-nf-conntrack.conf
# adjust_network
cp -f ../PATCH/adjust_network package/base-files/files/etc/init.d/zzz_adjust_network
# 删除已有配置
rm -rf .config
unalias wget
exit 0
