#!/bin/bash
set -x
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
# 更换GCC版本
rm -rf ./feeds/packages/devel/gcc
cp -rf ../others_src/openwrt_packages/devel/gcc   feeds/packages/devel/gcc
# 更换Node.js版本
rm -rf ./feeds/packages/lang/node
cp -rf ../others_src/openwrt_packages/lang/node   feeds/packages/lang/node
# 更换Golang版本
rm -rf ./feeds/packages/lang/golang
cp -rf ../others_src/openwrt_packages/lang/golang feeds/packages/lang/golang

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
# OC 1.5GHz
cp -f ../PATCH/999-RK3328-enable-1512mhz-opp.patch ./target/linux/rockchip/patches-5.4/999-RK3328-enable-1512mhz-opp.patch
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
cp -rf ../others_src/coolsnowwolf_lede/package/lean/shortcut-fe                   package/new/shortcut-fe
cp -rf ../others_src/coolsnowwolf_lede/package/lean/fast-classifier               package/new/fast-classifier
### 4. 更新部分软件包 ###
# AdGuard
cp -rf ../others_src/Lienol_openwrt_19.07/package/diy/luci-app-adguardhome        package/new/luci-app-adguardhome
cp -rf ../others_src/project-openwrt_openwrt_19.07/package/ntlf9t/AdGuardHome     package/new/AdGuardHome
# arpbind
cp -rf ../others_src/coolsnowwolf_lede/package/lean/luci-app-arpbind              package/lean/luci-app-arpbind
# AutoCore
cp -rf ../others_src/project-openwrt_openwrt/package/lean/autocore                package/lean/autocore
cp -rf ../others_src/coolsnowwolf_lede/package/lean/coremark                      package/lean/coremark
sed -i 's,-DMULTIT,-Ofast -DMULTIT,g' package/lean/coremark/Makefile
# AutoReboot定时重启
cp -rf ../others_src/coolsnowwolf_lede/package/lean/luci-app-autoreboot           package/lean/luci-app-autoreboot
# ChinaDNS
git clone -b luci   --single-branch https://github.com/pexcn/openwrt-chinadns-ng  package/new/luci-chinadns-ng
git clone -b master --single-branch https://github.com/pexcn/openwrt-chinadns-ng  package/new/chinadns-ng
cp -f ../PATCH/chinadnslist package/new/chinadns-ng/update-list.sh
pushd package/new/chinadns-ng
sed -i 's,/etc/chinadns-ng,files,g' ./update-list.sh
/bin/bash ./update-list.sh
popd
# DDNS
rm -rf ./feeds/packages/net/ddns-scripts ./feeds/luci/applications/luci-app-ddns
cp -rf ../others_src/coolsnowwolf_lede/package/lean/ddns-scripts_aliyun              package/lean/ddns-scripts_aliyun
cp -rf ../others_src/coolsnowwolf_lede/package/lean/ddns-scripts_dnspod              package/lean/ddns-scripts_dnspod
cp -rf ../others_src/openwrt_packages_18.06/net/ddns-scripts                         feeds/packages/net/ddns-scripts
cp -rf ../others_src/openwrt_luci_18.06/applications/luci-app-ddns                   feeds/luci/applications/luci-app-ddns
# 状态监控
cp -rf ../others_src/coolsnowwolf_lede/package/lean/luci-app-netdata                 package/lean/luci-app-netdata
# 清理内存
cp -rf ../others_src/coolsnowwolf_lede/package/lean/luci-app-ramfree                 package/lean/luci-app-ramfree
# 流量监视
git clone -b master --single-branch https://github.com/brvphoenix/wrtbwmon           package/new/wrtbwmon
git clone -b master --single-branch https://github.com/brvphoenix/luci-app-wrtbwmon  package/new/luci-app-wrtbwmon
# SSRP
cp -rf ../others_src/fw876_helloworld/luci-app-ssr-plus                              package/lean/luci-app-ssr-plus
cp -f  ../REPLACE/ssrurl.htm package/lean/luci-app-ssr-plus/luasrc/view/shadowsocksr/ssrurl.htm
# SSRP依赖
rm -rf ./feeds/packages/net/kcptun ./feeds/packages/net/shadowsocks-libev
cp -rf ../others_src/coolsnowwolf_lede/package/lean/shadowsocksr-libev               package/lean/shadowsocksr-libev
cp -rf ../others_src/coolsnowwolf_lede/package/lean/pdnsd-alt                        package/lean/pdnsd
cp -rf ../others_src/coolsnowwolf_lede/package/lean/v2ray                            package/lean/v2ray
cp -rf ../others_src/coolsnowwolf_lede/package/lean/kcptun                           package/lean/kcptun
cp -rf ../others_src/coolsnowwolf_lede/package/lean/v2ray-plugin                     package/lean/v2ray-plugin
cp -rf ../others_src/coolsnowwolf_lede/package/lean/srelay                           package/lean/srelay
cp -rf ../others_src/coolsnowwolf_lede/package/lean/microsocks                       package/lean/microsocks
cp -rf ../others_src/coolsnowwolf_lede/package/lean/dns2socks                        package/lean/dns2socks
cp -rf ../others_src/coolsnowwolf_lede/package/lean/redsocks2                        package/lean/redsocks2
cp -rf ../others_src/coolsnowwolf_lede/package/lean/proxychains-ng                   package/lean/proxychains-ng
cp -rf ../others_src/coolsnowwolf_lede/package/lean/ipt2socks                        package/lean/ipt2socks
cp -rf ../others_src/coolsnowwolf_lede/package/lean/simple-obfs                      package/lean/simple-obfs
cp -rf ../others_src/coolsnowwolf_packages/net/shadowsocks-libev                     package/lean/shadowsocks-libev
cp -rf ../others_src/project-openwrt_openwrt/package/lean/tcpping                    package/lean/tcpping
# PASSWALL
cp -rf ../others_src/Lienol_openwrt-package/lienol/luci-app-passwall                 package/new/luci-app-passwall
cp -rf ../others_src/Lienol_openwrt-package/package/tcping                           package/new/tcping
cp -rf ../others_src/Lienol_openwrt-package/package/trojan-go                        package/new/trojan-go
cp -rf ../others_src/Lienol_openwrt-package/package/brook                            package/new/brook
cp -rf ../others_src/Lienol_openwrt-package/package/trojan                           package/new/trojan
# OpenClash
cp -rf ../others_src/vernesong_OpenClash/luci-app-openclash                          package/new/luci-app-openclash
# 订阅转换
cp -rf ../others_src/project-openwrt_openwrt_19.07/package/ctcgfw/subconverter       package/new/subconverter
cp -rf ../others_src/project-openwrt_openwrt_19.07/package/ctcgfw/jpcre2             package/new/jpcre2
cp -rf ../others_src/project-openwrt_openwrt_19.07/package/ctcgfw/rapidjson          package/new/rapidjson
cp -rf ../others_src/project-openwrt_openwrt_19.07/package/ctcgfw/duktape            package/new/duktape
# 补全部分依赖（实际上并不会用到）
rm -rf ./feeds/packages/utils/collectd
cp -rf ../others_src/openwrt_packages/utils/collectd                                 feeds/packages/utils/collectd
cp -rf ../others_src/openwrt_openwrt_19.07/package/utils/fuse                        package/utils/fuse
cp -rf ../others_src/openwrt_openwrt_19.07/package/libs/libconfig                    package/libs/libconfig
# Zerotier
git clone https://github.com/rufengsuixing/luci-app-zerotier                         package/lean/luci-app-zerotier
cp -rf ../others_src/coolsnowwolf_packages/net/zerotier                              package/lean/zerotier
# argon主题
git clone -b master --single-branch https://github.com/jerrykuku/luci-theme-argon    package/new/luci-theme-argon
# edge主题
git clone -b master --single-branch https://github.com/garypang13/luci-theme-edge    package/new/luci-theme-edge
# 翻译及部分功能优化
git clone -b master --single-branch https://github.com/QiuSimons/addition-trans-zh   package/lean/lean-translate
cp -f ../REPLACE/zzz-default-settings package/lean/lean-translate/files/zzz-default-settings
# 给root用户添加vim和screen的配置文件
mkdir -p                   package/base-files/files/root
cp -f ../PRECONFS/vimrc    package/base-files/files/root/.vimrc
cp -f ../PRECONFS/screenrc package/base-files/files/root/.screenrc
## 最后的收尾工作
mkdir -p                    package/base-files/files/usr/bin
cp -f ../PATCH/chinadnslist package/base-files/files/usr/bin/update-chinadns-list
# 最大连接
sed -i 's/16384/65536/g'    package/kernel/linux/files/sysctl-nf-conntrack.conf
# 修正架构
sed -i "s,boardinfo.system,'ARMv8',g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
# adjust_network
cp  -f ../PATCH/adjust_network        package/base-files/files/etc/init.d/zzz_adjust_network
# 删除已有配置
rm -rf .config
unalias wget
exit 0
