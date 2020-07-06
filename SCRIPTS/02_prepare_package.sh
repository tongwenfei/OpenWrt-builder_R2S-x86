#!/bin/bash
## 准备工作
# 使用19.07的feed源
rm -f ./feeds.conf.default
wget --https-only https://raw.githubusercontent.com/openwrt/openwrt/openwrt-19.07/feeds.conf.default
# remove annoying snapshot tag
sed -i "s,SNAPSHOT,$(date '+%Y.%m.%d'),g" include/version.mk
sed -i "s,snapshots,$(date '+%Y.%m.%d'),g" package/base-files/image-config.in
# 使用O3级别的优化
sed -i 's/Os/O3/g' include/target.mk
sed -i 's/O2/O3/g' ./rules.mk
# 更新feed
./scripts/feeds update -a && ./scripts/feeds install -a
# 更换GCC版本
rm -rf ./feeds/packages/devel/gcc
svn co https://github.com/openwrt/packages/trunk/devel/gcc feeds/packages/devel/gcc
# 更换Python版本（含Py3和Py2）
rm -rf ./feeds/packages/lang/python
mv ../PYTHON_KEEP ./feeds/packages/lang/python
# 更换Node.js版本
rm -rf ./feeds/packages/lang/node
svn co https://github.com/openwrt/packages/trunk/lang/node feeds/packages/lang/node
# irqbalance
sed -i 's/0/1/g' feeds/packages/utils/irqbalance/files/irqbalance.config
## 必要的patch
wget --https-only -P include/ https://raw.githubusercontent.com/openwrt/openwrt/openwrt-19.07/include/scons.mk
# Patch jsonc
patch -p1 < ../PATCH/use_json_object_new_int64.patch
# dnsmasq filter AAAA
patch -p1 < ../PATCH/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/luci-add-filter-aaaa-option.patch
cp -f ../PATCH/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
# Patch FireWall 以增添fullcone功能
mkdir package/network/config/firewall/patches
wget --https-only -P package/network/config/firewall/patches/ https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/fullconenat.patch
# Patch LuCI 以增添fullcone开关
pushd feeds/luci
wget --https-only -O- https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/luci.patch | git apply
popd
# Patch Kernel 以解决fullcone冲突
pushd target/linux/generic/hack-5.4
wget --https-only https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd
# Patch FireWall 以增添SFE
patch -p1 < ../PATCH/luci-app-firewall_add_sfe_switch.patch
# SFE内核补丁
pushd target/linux/generic/hack-5.4
wget --https-only https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/999-shortcut-fe-support.patch
popd
# update zstd to 1.4.5
rm -rf ./feeds/packages/utils/zstd
svn co https://github.com/openwrt/packages/trunk/utils/zstd feeds/packages/utils/zstd
# arpbind
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-arpbind package/lean/luci-app-arpbind
# Adbyby
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-adbyby-plus package/lean/luci-app-adbyby-plus
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/adbyby package/lean/coremark/adbyby
# AutoCore
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/lean/autocore package/lean/autocore
sed -i "s,@TARGET_x86 ,,g" package/lean/autocore/Makefile
rm -rf ./package/lean/autocore/files/cpuinfo
wget --https-only -P package/lean/autocore/files https://raw.githubusercontent.com/QiuSimons/Others/master/cpuinfo
rm -rf ./package/lean/autocore/files/rpcd_10_system.js
wget --https-only -P package/lean/autocore/files https://raw.githubusercontent.com/QiuSimons/Others/master/rpcd_10_system.js
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/lean/coremark package/lean/coremark
sed -i 's,-DMULTIT,-Ofast -DMULTIT,g' package/lean/coremark/Makefile
# DDNS
rm -rf ./feeds/packages/net/ddns-scripts
rm -rf ./feeds/luci/applications/luci-app-ddns
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_aliyun package/lean/ddns-scripts_aliyun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_dnspod package/lean/ddns-scripts_dnspod
svn co https://github.com/openwrt/packages/branches/openwrt-18.06/net/ddns-scripts feeds/packages/net/ddns-scripts
svn co https://github.com/openwrt/luci/branches/openwrt-18.06/applications/luci-app-ddns feeds/luci/applications/luci-app-ddns
# 定时重启
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot package/lean/luci-app-autoreboot
# argon主题
git clone -b master --single-branch https://github.com/jerrykuku/luci-theme-argon package/new/luci-theme-argon
# SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus package/lean/luci-app-ssr-plus
rm -rf ./package/lean/luci-app-ssr-plus/luasrc/view/shadowsocksr/ssrurl.htm
wget --https-only -P package/lean/luci-app-ssr-plus/luasrc/view/shadowsocksr https://raw.githubusercontent.com/QiuSimons/Others/master/luci-app-ssr-plus/luasrc/view/shadowsocksr/ssrurl.htm
# SSRP依赖
rm -rf ./feeds/packages/net/kcptun
rm -rf ./feeds/packages/net/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shadowsocksr-libev package/lean/shadowsocksr-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt package/lean/pdnsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray package/lean/v2ray
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/kcptun package/lean/kcptun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray-plugin package/lean/v2ray-plugin
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/srelay package/lean/srelay
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks package/lean/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2 package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/proxychains-ng package/lean/proxychains-ng
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks package/lean/ipt2socks
git clone -b master --single-branch https://github.com/aa65535/openwrt-simple-obfs package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev package/lean/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan package/lean/trojan
svn co https://github.com/project-openwrt/openwrt/trunk/package/lean/tcpping package/lean/tcpping
# 订阅转换
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/subconverter package/new/subconverter
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/jpcre2 package/new/jpcre2
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/rapidjson package/new/rapidjson
# 清理内存
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree package/lean/luci-app-ramfree
# 流量监视
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-wrtbwmon package/lean/luci-app-wrtbwmon
# 流量监管
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-netdata package/lean/luci-app-netdata
# OpenClash
svn co https://github.com/vernesong/OpenClash/branches/master/luci-app-openclash package/new/luci-app-openclash
# 补全部分依赖（实际上并不会用到）
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/utils/fuse package/utils/fuse
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libconfig package/libs/libconfig
rm -rf ./feeds/packages/utils/collectd
svn co https://github.com/openwrt/packages/trunk/utils/collectd feeds/packages/utils/collectd
# Zerotier
git clone https://github.com/rufengsuixing/luci-app-zerotier package/lean/luci-app-zerotier
svn co https://github.com/coolsnowwolf/packages/trunk/net/zerotier package/lean/zerotier
# FullCone模块
git clone -b master --single-branch https://github.com/QiuSimons/openwrt-fullconenat package/fullconenat
# 翻译及部分功能优化
git clone -b master --single-branch https://github.com/QiuSimons/addition-trans-zh package/lean/lean-translate
# SFE
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe package/new/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/new/fast-classifier
## 最后的收尾工作
# 最大连接
sed -i 's/16384/65536/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 修正架构
sed -i "s,boardinfo.system,'ARMv8',g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
# adjust_network
cp -f ../PATCH/adjust_network package/base-files/files/etc/init.d/zzz_adjust_network
# 删除已有配置
rm -rf .config
# 授予权限
chmod -R 755 ./
exit 0
