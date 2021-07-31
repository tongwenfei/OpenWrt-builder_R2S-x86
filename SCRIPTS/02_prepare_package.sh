#!/bin/bash
set -x
set -e
alias wget="$(which wget) --https-only --retry-connrefused"

# 如果没有环境变量或无效，则默认构建R2S版本
[ -f "../SEED/${MYOPENWRTTARGET}.config.seed" ] || MYOPENWRTTARGET='R2S'
echo "==> Now building: ${MYOPENWRTTARGET}"

### 1. 准备工作 ###
# R2S专用
if [ "${MYOPENWRTTARGET}" = 'R2S' ] ; then
  sed -i 's,-mcpu=generic,-mcpu=cortex-a53+crypto,g' include/target.mk
  cp -f ../PATCH/mbedtls/100-Implements-AES-and-GCM-with-ARMv8-Crypto-Extensions.patch ./package/libs/mbedtls/patches/100-Implements-AES-and-GCM-with-ARMv8-Crypto-Extensions.patch
  # 采用immortalwrt的优化
  rm -rf ./target/linux/rockchip ./package/boot/uboot-rockchip ./package/boot/arm-trusted-firmware-rk3328
  svn co https://github.com/immortalwrt/immortalwrt/branches/master/target/linux/rockchip                    target/linux/rockchip
  svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/boot/uboot-rockchip              package/boot/uboot-rockchip
  svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/boot/arm-trusted-firmware-rk3328 package/boot/arm-trusted-firmware-rk3328
  # overclocking 1.5GHz
  cp -f ../PATCH/999-RK3328-enable-1512mhz-opp.patch target/linux/rockchip/patches-5.4/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch
fi
# 使用O2级别的优化
sed -i 's/ -Os / -O2 -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections /g' include/target.mk
# feed调节
sed -i '/telephony/d' feeds.conf.default
# 更新feed
./scripts/feeds update -a
./scripts/feeds install -a
# something called magic
rm -rf ./scripts/download.pl ./include/download.mk
wget -P include/ https://raw.githubusercontent.com/immortalwrt/immortalwrt/openwrt-21.02/include/download.mk
wget -P scripts/ https://raw.githubusercontent.com/immortalwrt/immortalwrt/openwrt-21.02/scripts/download.pl
sed -i '/\.cn\//d'   scripts/download.pl
sed -i '/aliyun/d'   scripts/download.pl
sed -i '/cnpmjs/d'   scripts/download.pl
sed -i '/fastgit/d'  scripts/download.pl
sed -i '/ghproxy/d'  scripts/download.pl
sed -i '/mirror02/d' scripts/download.pl
sed -i '/sevencdn/d' scripts/download.pl
sed -i '/tencent/d'  scripts/download.pl
sed -i '/zwc365/d'   scripts/download.pl
sed -i '/182\.140\.223\.146/d' scripts/download.pl
chmod +x scripts/download.pl

### 2. 必要的Patch ###
# 根据体系调整
case ${MYOPENWRTTARGET} in
  R2S)
    # show cpu model name
    wget -P target/linux/generic/hack-5.4/ https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/target/linux/generic/hack-5.4/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
    # IRQ and disabed rk3328 ethernet tcp/udp offloading tx/rx
    patch -p1 < ../PATCH/0002-IRQ-and-disable-eth0-tcp-udp-offloading-tx-rx.patch
    # 添加 GPU 驱动
    rm -rf  package/kernel/linux/modules/video.mk
    wget -P package/kernel/linux/modules/ https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/package/kernel/linux/modules/video.mk
    # 交换 LAN WAN
    patch -p1 < ../PATCH/R2S-swap-LAN-WAN.patch
    ;;
  x86)
    # 默认开启 irqbalance
    sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config
    ;;
esac
# GCC11
rm -rf ./toolchain/gcc
svn co https://github.com/openwrt/openwrt/trunk/toolchain/gcc                  toolchain/gcc
rm -rf ./package/network/utils/bpftools
svn co https://github.com/openwrt/openwrt/trunk/package/network/utils/bpftools package/network/utils/bpftools
rm -rf ./feeds/packages/libs/dtc
svn co https://github.com/openwrt/packages/trunk/libs/dtc                      feeds/packages/libs/dtc
rm -rf ./package/libs/elfutils
svn co https://github.com/neheb/openwrt/branches/elf/package/libs/elfutils     package/libs/elfutils
# grub2强制使用O2级别优化
wget -qO - https://github.com/QiuSimons/openwrt-NoTengoBattery/commit/71d808b9efdb8635db1ae3b86f39dd25dc711811.patch | patch -p1
# BBRv2
patch -p1 < ../PATCH/BBRv2/openwrt-kmod-bbr2.patch
cp -f ../PATCH/BBRv2/693-Add_BBRv2_congestion_control_for_Linux_TCP.patch ./target/linux/generic/hack-5.4/693-Add_BBRv2_congestion_control_for_Linux_TCP.patch
wget -qO - https://github.com/openwrt/openwrt/commit/cfaf039b0e5cf4c38b88c20540c76b10eac3078d.patch | patch -p1
# Patch jsonc
patch -p1 < ../PATCH/jsonc/use_json_object_new_int64.patch
# Patch dnsmasq filter AAAA
patch -p1 < ../PATCH/dnsmasq/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/dnsmasq/luci-add-filter-aaaa-option.patch
cp  -f      ../PATCH/dnsmasq/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
# Patch Kernel 以解决FullCone冲突
pushd target/linux/generic/hack-5.4
  wget https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd
# Patch FireWall 以增添FullCone功能
mkdir -p package/network/config/firewall/patches
wget  -P package/network/config/firewall/patches/ https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/package/network/config/firewall/patches/fullconenat.patch
wget -qO- https://raw.githubusercontent.com/msylgj/R2S-R4S-OpenWrt/21.02/SCRIPTS/fix_firewall_flock.patch | patch -p1
# Patch LuCI 以增添FullCone开关
patch -p1 < ../PATCH/firewall/luci-app-firewall_add_fullcone.patch
# FullCone 相关组件
cp -rf ../openwrt-lienol/package/network/fullconenat ./package/network/fullconenat
# UPX
sed -i '/patchelf pkgconf/i\tools-y += ucl upx'                                  ./tools/Makefile
sed -i '\/autoconf\/compile :=/i\$(curdir)/upx/compile := $(curdir)/ucl/compile' ./tools/Makefile
svn co https://github.com/immortalwrt/immortalwrt/branches/master/tools/upx tools/upx
svn co https://github.com/immortalwrt/immortalwrt/branches/master/tools/ucl tools/ucl
# 修复由于shadow-utils引起的管理页面修改密码功能失效的问题
pushd feeds/luci
  patch -p1 < ../../../PATCH/let-luci-use-busybox-passwd.patch
popd

### 3. 更新部分软件包 ###
mkdir -p ./package/new/ ./package/lean/
# AutoCore & coremark
rm -rf ./feeds/packages/utils/coremark
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/emortal/autocore package/lean/autocore
svn co https://github.com/immortalwrt/packages/trunk/utils/coremark                        feeds/packages/utils/coremark
# AutoReboot定时重启
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot         package/lean/luci-app-autoreboot
# ipv6-helper
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipv6-helper                 package/lean/ipv6-helper
# 清理内存
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree            package/lean/luci-app-ramfree
# 流量监视
git clone -b master --depth=1 https://github.com/brvphoenix/wrtbwmon                       package/new/wrtbwmon
git clone -b master --depth=1 https://github.com/brvphoenix/luci-app-wrtbwmon              package/new/luci-app-wrtbwmon
# Dnsproxy
svn co https://github.com/immortalwrt/packages/trunk/net/dnsproxy                          feeds/packages/net/dnsproxy
ln -sf ../../../feeds/packages/net/dnsproxy                                              ./package/feeds/packages/dnsproxy
# Haproxy
rm -rf ./feeds/packages/net/haproxy
svn co https://github.com/openwrt/packages/trunk/net/haproxy                               feeds/packages/net/haproxy
pushd feeds/packages
  wget -qO - https://github.com/QiuSimons/packages/commit/e365bd289f51a6ab18e0a9769543c09030b7650f.patch | patch -p1
popd
# socat
svn co https://github.com/Lienol/openwrt-package/trunk/luci-app-socat                      package/new/luci-app-socat
# SSRP依赖
rm -rf ./feeds/packages/net/xray-core ./feeds/packages/net/kcptun ./feeds/packages/net/shadowsocks-libev ./feeds/packages/net/proxychains-ng ./feeds/packages/net/shadowsocks-rust
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks                package/lean/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks                package/lean/ipt2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks               package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt                package/lean/pdnsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2                package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs              package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/srelay                   package/lean/srelay
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan                   package/lean/trojan
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev             package/lean/shadowsocks-libev
svn co https://github.com/fw876/helloworld/trunk/naiveproxy                             package/lean/naiveproxy
svn co https://github.com/fw876/helloworld/trunk/shadowsocksr-libev                     package/lean/shadowsocksr-libev
svn co https://github.com/fw876/helloworld/trunk/v2ray-core                             package/lean/v2ray-core
svn co https://github.com/fw876/helloworld/trunk/xray-core                              package/lean/xray-core
svn co https://github.com/fw876/helloworld/trunk/xray-plugin                            package/lean/xray-plugin
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/brook                        package/new/brook
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/ssocks                       package/new/ssocks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/tcping                       package/new/tcping
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-go                    package/new/trojan-go
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-plus                  package/new/trojan-plus
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/v2ray-plugin                 package/new/v2ray-plugin
svn co https://github.com/immortalwrt/packages/trunk/net/proxychains-ng                 package/lean/proxychains-ng
svn co https://github.com/immortalwrt/packages/trunk/net/kcptun                         feeds/packages/net/kcptun
svn co https://github.com/immortalwrt/packages/trunk/net/shadowsocks-rust               feeds/packages/net/shadowsocks-rust
ln -sf ../../../feeds/packages/net/kcptun                                             ./package/feeds/packages/kcptun
ln -sf ../../../feeds/packages/net/shadowsocks-rust                                   ./package/feeds/packages/shadowsocks-rust
# OpenClash
git clone -b dev --depth=1 https://github.com/vernesong/OpenClash                       package/new/luci-app-openclash
# SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus                      package/lean/luci-app-ssr-plus
pushd package/lean
  patch -p1 < ../../../PATCH/0005-add-QiuSimons-Chnroute-to-chnroute-url.patch
  wget -qO - https://patch-diff.githubusercontent.com/raw/fw876/helloworld/pull/606.patch | patch -p1
popd
# 订阅转换
svn co https://github.com/immortalwrt/packages/trunk/libs/jpcre2      feeds/packages/libs/jpcre2
svn co https://github.com/immortalwrt/packages/trunk/libs/libcron     feeds/packages/libs/libcron
svn co https://github.com/immortalwrt/packages/trunk/libs/quickjspp   feeds/packages/libs/quickjspp
svn co https://github.com/immortalwrt/packages/trunk/libs/rapidjson   feeds/packages/libs/rapidjson
svn co https://github.com/immortalwrt/packages/trunk/net/subconverter feeds/packages/net/subconverter
ln -sf ../../../feeds/packages/libs/jpcre2      ./package/feeds/packages/jpcre2
ln -sf ../../../feeds/packages/libs/libcron     ./package/feeds/packages/libcron
ln -sf ../../../feeds/packages/libs/quickjspp   ./package/feeds/packages/quickjspp
ln -sf ../../../feeds/packages/libs/rapidjson   ./package/feeds/packages/rapidjson
ln -sf ../../../feeds/packages/net/subconverter ./package/feeds/packages/subconverter
# 额外DDNS脚本
git clone --depth 1 https://github.com/small-5/ddns-scripts-dnspod               package/lean/ddns-scripts_dnspod
git clone --depth 1 https://github.com/small-5/ddns-scripts-aliyun               package/lean/ddns-scripts_aliyun
# UPnP
rm -rf ./feeds/packages/net/miniupnpd
svn co https://github.com/openwrt/packages/trunk/net/miniupnpd                   feeds/packages/net/miniupnpd
# Zerotier
svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-zerotier  feeds/luci/applications/luci-app-zerotier
ln -sf ../../../feeds/luci/applications/luci-app-zerotier                      ./package/feeds/luci/luci-app-zerotier
rm -rf ./feeds/packages/net/zerotier/files/etc/init.d/zerotier
# CPU限制
svn co https://github.com/immortalwrt/packages/trunk/utils/cpulimit              feeds/packages/utils/cpulimit
ln -sf ../../../feeds/packages/utils/cpulimit                                  ./package/feeds/packages/cpulimit
svn co https://github.com/QiuSimons/OpenWrt-Add/trunk/luci-app-cpulimit          package/lean/luci-app-cpulimit
cp -f ../PATCH/luci-app-cpulimit_config/cpulimit                               ./package/lean/luci-app-cpulimit/root/etc/config/cpulimit
# CPU主频
if [ "${MYOPENWRTTARGET}" = 'R2S' ] ; then
  svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-cpufreq feeds/luci/applications/luci-app-cpufreq
  ln -sf ../../../feeds/luci/applications/luci-app-cpufreq                     ./package/feeds/luci/luci-app-cpufreq
fi
# 翻译及部分功能优化
svn co https://github.com/QiuSimons/OpenWrt-Add/trunk/addition-trans-zh          package/lean/lean-translate
if [ "${MYOPENWRTTARGET}" != 'R2S' ] ; then
  sed -i '/openssl\.cnf/d' ../PATCH/addition-trans-zh/files/zzz-default-settings
  sed -i '/upnp/Id'        ../PATCH/addition-trans-zh/files/zzz-default-settings
fi
cp -f ../PATCH/addition-trans-zh/files/zzz-default-settings ./package/lean/lean-translate/files/zzz-default-settings
# 给root用户添加vim和screen的配置文件
mkdir -p                                    ./package/base-files/files/root/
cp -f ../PRECONFS/vimrc                     ./package/base-files/files/root/.vimrc
cp -f ../PRECONFS/screenrc                  ./package/base-files/files/root/.screenrc

### 4. 最后的收尾工作 ###
# 最大连接
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
echo 'net.netfilter.nf_conntrack_helper = 1' >> package/kernel/linux/files/sysctl-nf-conntrack.conf
# crypto相关
if [ "${MYOPENWRTTARGET}" = 'x86' ] ; then
  echo 'CONFIG_CRYPTO_AES_NI_INTEL=y' >> ./target/linux/x86/64/config-5.4
fi
# 删除已有配置
rm -rf .config
# 删除.svn目录
find ./ -type d -name '.svn' -print0 | xargs -0 -s1024 /bin/rm -rf
unalias wget
