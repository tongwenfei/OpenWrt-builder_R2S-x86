#!/bin/bash
set -x
set -e
alias wget="$(which wget) --https-only --retry-connrefused"

# 如果没有环境变量或无效，则默认构建R2S版本
[ -n "$MYOPENWRTTARGET" ] && [ -d ../SEED/$MYOPENWRTTARGET ] || MYOPENWRTTARGET='R2S'
echo "==> Now building: $MYOPENWRTTARGET"

### 1. 准备工作 ###
# 使用O2级别的优化
sed -i 's/-Os/-O2/g' include/target.mk
if [ "$MYOPENWRTTARGET" = 'R2S' ] ; then
  sed -i 's,-mcpu=generic,-march=armv8-a+crypto+crc -mcpu=cortex-a53+crypto+crc -mtune=cortex-a53,g' include/target.mk
fi
# 更新feed
./scripts/feeds update -a
./scripts/feeds install -a

### 2. 必要的Patch ###
# 更换cryptodev-linux
rm -rf ./package/kernel/cryptodev-linux
svn co https://github.com/openwrt/openwrt/trunk/package/kernel/cryptodev-linux package/kernel/cryptodev-linux
case $MYOPENWRTTARGET in
  R2S)
    # show cpu model name
    wget -P target/linux/generic/pending-5.4  https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/target/linux/generic/pending-5.4/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
    # 3328 add idle
    wget -P target/linux/rockchip/patches-5.4 https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/target/linux/rockchip/patches-5.4/007-arm64-dts-rockchip-Add-RK3328-idle-state.patch
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
    ;;
  x86)
    # irqbalance
    sed -i 's/0/1/g' feeds/packages/utils/irqbalance/files/irqbalance.config
    ;;
esac
# Patch jsonc
patch -p1 < ../PATCH/new/package/use_json_object_new_int64.patch
# Patch dnsmasq filter AAAA
patch -p1 < ../PATCH/new/package/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/new/package/luci-add-filter-aaaa-option.patch
cp  -f      ../PATCH/new/package/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
rm -rf ./package/base-files/files/etc/init.d/boot
wget  -P package/base-files/files/etc/init.d/ https://raw.githubusercontent.com/immortalwrt/immortalwrt/openwrt-18.06-k5.4/package/base-files/files/etc/init.d/boot
# Patch Kernel 以解决FullCone冲突
pushd target/linux/generic/hack-5.4
  wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd
# Patch FireWall 以增添FullCone功能
mkdir -p package/network/config/firewall/patches
wget  -P package/network/config/firewall/patches/ https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/package/network/config/firewall/patches/fullconenat.patch
# Patch LuCI 以增添FullCone开关
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_fullcone.patch
# FullCone 相关组件
cp -rf ../openwrt-lienol/package/network/fullconenat                         ./package/network/fullconenat
# Patch Kernel 以支持SFE
pushd target/linux/generic/hack-5.4
  wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
popd
# Patch LuCI 以增添SFE开关
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_sfe_switch.patch
# SFE 相关组件
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe     package/lean/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/lean/fast-classifier
cp -f ../PATCH/duplicate/shortcut-fe                                         ./package/base-files/files/etc/init.d/
# 修复由于shadow-utils引起的管理页面修改密码功能失效的问题
pushd feeds/luci
  patch -p1 < ../../../PATCH/let-luci-use-busybox-passwd.patch
popd

### 3. 更新部分软件包 ###
mkdir -p ./package/new/ ./package/lean/
# AdGuard
sed -i '/init/d' ./feeds/packages/net/adguardhome/Makefile
cp -rf ../openwrt-lienol/package/diy/luci-app-adguardhome                               ./package/new/luci-app-adguardhome
# arpbind
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-arpbind           package/lean/luci-app-arpbind
# AutoCore & coremark
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/autocore   package/lean/autocore
svn co https://github.com/immortalwrt/packages/trunk/utils/coremark                       feeds/packages/utils/coremark
sed -i 's,default n,default y,g' ./feeds/packages/utils/coremark/Makefile
ln -sf ../../../feeds/packages/utils/coremark ./package/feeds/packages/coremark
# AutoReboot定时重启
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot        package/lean/luci-app-autoreboot
# DDNS
rm -rf ./feeds/packages/net/ddns-scripts ./feeds/luci/applications/luci-app-ddns
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_aliyun        package/lean/ddns-scripts_aliyun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_dnspod        package/lean/ddns-scripts_dnspod
svn co https://github.com/openwrt/packages/branches/openwrt-18.06/net/ddns-scripts        feeds/packages/net/ddns-scripts
svn co https://github.com/openwrt/luci/branches/openwrt-18.06/applications/luci-app-ddns  feeds/luci/applications/luci-app-ddns
# ipv6-helper
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipv6-helper                package/lean/ipv6-helper
# CPU限制
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ntlf9t/cpulimit package/lean/cpulimit
cp -rf ../PATCH/duplicate/luci-app-cpulimit                                             ./package/lean/luci-app-cpulimit
# 清理内存
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree           package/lean/luci-app-ramfree
# 流量监视
git clone -b master --depth 1 https://github.com/brvphoenix/wrtbwmon                      package/new/wrtbwmon
git clone -b master --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon             package/new/luci-app-wrtbwmon
# SmartDNS
cp -rf ../packages-lienol/net/smartdns                  ./package/new/smartdns
# OpenClash
git clone -b master --depth 1 https://github.com/vernesong/OpenClash                   package/new/luci-app-openclash
# SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus                     package/lean/luci-app-ssr-plus
pushd package/lean
  patch -p1 < ../../../PATCH/0002-add-QiuSimons-Chnroute-to-chnroute-url.patch
popd
# SSRP依赖
rm -rf ./feeds/packages/net/xray-core ./feeds/packages/net/kcptun ./feeds/packages/net/shadowsocks-libev ./feeds/packages/net/proxychains-ng
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
svn co https://github.com/fw876/helloworld/trunk/naiveproxy                            package/lean/naiveproxy
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/tcpping package/lean/tcpping
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/tcping                      package/new/tcping
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-go                   package/new/trojan-go
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/brook                       package/new/brook
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-plus                 package/new/trojan-plus
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/ssocks                      package/new/ssocks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/v2ray                       package/new/v2ray
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/v2ray-plugin                package/new/v2ray-plugin
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/xray-core                   package/new/xray-core
# 订阅转换
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/subconverter package/new/subconverter
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/jpcre2       package/new/jpcre2
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/rapidjson    package/new/rapidjson
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/ctcgfw/duktape      package/new/duktape
# Zerotier
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/luci-app-zerotier     package/lean/luci-app-zerotier
rm -rf ./feeds/packages/net/zerotier/files/etc/init.d/zerotier
# 翻译及部分功能优化
if [ "$MYOPENWRTTARGET" != 'R2S' ] ; then
  sed -i '/openssl\.cnf/d' ../PATCH/duplicate/addition-trans-zh/files/zzz-default-settings
fi
cp -rf ../PATCH/duplicate/addition-trans-zh ./package/lean/lean-translate
# 给root用户添加vim和screen的配置文件
mkdir -p                                    ./package/base-files/files/root/
cp -f ../PRECONFS/vimrc                     ./package/base-files/files/root/.vimrc
cp -f ../PRECONFS/screenrc                  ./package/base-files/files/root/.screenrc
# 暂时解决要求libncursesw6的问题
cp -rf ../PATCH/duplicate/libncursesw6      ./package/lean/libncursesw6

### 4. 最后的收尾工作 ###
# 最大连接
sed -i 's/16384/65536/g'   ./package/kernel/linux/files/sysctl-nf-conntrack.conf
# crypto相关
if [ "$MYOPENWRTTARGET" = 'R2S' ] ; then
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
fi
# 删除已有配置
rm -rf .config
# 删除.svn目录
find ./ -type d -name '.svn' -print0 | xargs -0 -s1024 /bin/rm -rf
unalias wget
exit 0
