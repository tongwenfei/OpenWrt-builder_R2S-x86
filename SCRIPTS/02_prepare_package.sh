#!/bin/bash
set -x
set -e
alias wget="$(which wget) --https-only --retry-connrefused"

# 如果没有环境变量或无效，则默认构建R2S版本
[ -f "../SEED/${MYOPENWRTTARGET}.config.seed" ] || MYOPENWRTTARGET='R2S'
echo "==> Now building: ${MYOPENWRTTARGET}"

### 1. 准备工作 ###
# 使用O2级别的优化
sed -i 's/-Os/-O2/g' include/target.mk
if [ "${MYOPENWRTTARGET}" = 'R2S' ] ; then
  sed -i 's,-mcpu=generic,-march=armv8-a+crypto+crc -mabi=lp64,g' include/target.mk
  cp -f ../PATCH/new/package/100-Implements-AES-and-GCM-with-ARMv8-Crypto-Extensions.patch ./package/libs/mbedtls/patches/100-Implements-AES-and-GCM-with-ARMv8-Crypto-Extensions.patch
  # 采用immortalwrt的优化
  rm -rf ./target/linux/rockchip ./package/boot/uboot-rockchip ./package/boot/arm-trusted-firmware-rk3328
  svn co https://github.com/immortalwrt/immortalwrt/branches/master/target/linux/rockchip                    target/linux/rockchip
  svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/boot/uboot-rockchip              package/boot/uboot-rockchip
  svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/boot/arm-trusted-firmware-rk3328 package/boot/arm-trusted-firmware-rk3328
  # overclocking 1.5GHz
  cp -f ../PATCH/999-RK3328-enable-1512mhz-opp.patch target/linux/rockchip/patches-5.4/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch
fi
# feed调节
sed -i '/telephony/d' feeds.conf.default
# 更新feed
./scripts/feeds update -a
./scripts/feeds install -a
# remove annoying snapshot tag
sed -i "s,SNAPSHOT,$(date '+%Y.%m.%d'),g"  include/version.mk
# something called magic
rm -rf ./scripts/download.pl ./include/download.mk
wget -P scripts/ https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/scripts/download.pl
wget -P include/ https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/include/download.mk
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

# kernel update
wget -qO - https://patch-diff.githubusercontent.com/raw/openwrt/openwrt/pull/4133.patch | patch -p1

### 2. 必要的Patch ###
case ${MYOPENWRTTARGET} in
  R2S)
    # show cpu model name
    wget -P target/linux/generic/pending-5.4/ https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/target/linux/generic/hack-5.4/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
    # IRQ and disabed rk3328 ethernet tcp/udp offloading tx/rx
    patch -p1 < ../PATCH/new/main/0002-IRQ-and-disable-eth0-tcp-udp-offloading-tx-rx.patch
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
# Patch jsonc
patch -p1 < ../PATCH/new/package/use_json_object_new_int64.patch
# Patch dnsmasq filter AAAA
patch -p1 < ../PATCH/new/package/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/new/package/luci-add-filter-aaaa-option.patch
cp  -f      ../PATCH/new/package/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
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
cp -rf ../openwrt-lienol/package/network/fullconenat ./package/network/fullconenat
# 修复由于shadow-utils引起的管理页面修改密码功能失效的问题
pushd feeds/luci
  patch -p1 < ../../../PATCH/let-luci-use-busybox-passwd.patch
popd

### 3. 更新部分软件包 ###
mkdir -p ./package/new/ ./package/lean/
# AdGuard
sed -i '/init/d' feeds/packages/net/adguardhome/Makefile
cp -rf ../openwrt-lienol/package/diy/luci-app-adguardhome                             ./package/new/luci-app-adguardhome
# AutoCore & coremark
rm -rf ./feeds/packages/utils/coremark
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/autocore package/lean/autocore
svn co https://github.com/immortalwrt/packages/trunk/utils/coremark                     feeds/packages/utils/coremark
# AutoReboot定时重启
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot      package/lean/luci-app-autoreboot
# ipv6-helper
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipv6-helper              package/lean/ipv6-helper
# 清理内存
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree         package/lean/luci-app-ramfree
# 流量监视
git clone -b master --depth=1 https://github.com/brvphoenix/wrtbwmon                    package/new/wrtbwmon
git clone -b master --depth=1 https://github.com/brvphoenix/luci-app-wrtbwmon           package/new/luci-app-wrtbwmon
# SmartDNS
rm -rf ./feeds/packages/net/smartdns ./feeds/luci/applications/luci-app-smartdns
svn co https://github.com/Lienol/openwrt-packages/trunk/net/smartdns                             feeds/packages/net/smartdns
svn co https://github.com/immortalwrt/luci/branches/openwrt-18.06/applications/luci-app-smartdns feeds/luci/applications/luci-app-smartdns
# SSRP依赖
rm -rf ./feeds/packages/net/xray-core ./feeds/packages/net/kcptun ./feeds/packages/net/shadowsocks-libev ./feeds/packages/net/proxychains-ng
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks                package/lean/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks                package/lean/ipt2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/kcptun                   package/lean/kcptun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks               package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt                package/lean/pdnsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/proxychains-ng           package/lean/proxychains-ng
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2                package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shadowsocksr-libev       package/lean/shadowsocksr-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs              package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/srelay                   package/lean/srelay
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan                   package/lean/trojan
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev             package/lean/shadowsocks-libev
svn co https://github.com/fw876/helloworld/trunk/naiveproxy                             package/lean/naiveproxy
svn co https://github.com/fw876/helloworld/trunk/v2ray-core                             package/lean/v2ray-core
svn co https://github.com/fw876/helloworld/trunk/xray-core                              package/lean/xray-core
svn co https://github.com/fw876/helloworld/trunk/xray-plugin                            package/lean/xray-plugin
svn co https://github.com/immortalwrt/packages/trunk/net/shadowsocks-rust               package/lean/shadowsocks-rust
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/brook                        package/new/brook
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/ssocks                       package/new/ssocks
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/tcping                       package/new/tcping
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-go                    package/new/trojan-go
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/trojan-plus                  package/new/trojan-plus
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/v2ray-plugin                 package/new/v2ray-plugin
# OpenClash
git clone -b master --depth=1 https://github.com/vernesong/OpenClash                    package/new/luci-app-openclash
# SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus                      package/lean/luci-app-ssr-plus
pushd package/lean
  patch -p1 < ../../../PATCH/0002-add-QiuSimons-Chnroute-to-chnroute-url.patch
  wget -qO - https://patch-diff.githubusercontent.com/raw/fw876/helloworld/pull/509.patch | patch -p1
  wget -qO - https://github.com/QiuSimons/helloworld-fw876/commit/c1674ad3b83b60aeab723da1f48201929507a131.patch | patch -p1
popd
# 订阅转换
svn co https://github.com/immortalwrt/packages/trunk/net/subconverter package/new/subconverter
svn co https://github.com/immortalwrt/packages/trunk/libs/jpcre2      package/new/jpcre2
svn co https://github.com/immortalwrt/packages/trunk/libs/rapidjson   package/new/rapidjson
svn co https://github.com/immortalwrt/packages/trunk/libs/libcron     package/new/libcron
svn co https://github.com/immortalwrt/packages/trunk/libs/quickjspp   package/new/quickjspp
# CPU限制
svn co https://github.com/immortalwrt/packages/trunk/utils/cpulimit   package/lean/cpulimit
cp -rf ../PATCH/duplicate/luci-app-cpulimit                         ./package/lean/luci-app-cpulimit
# 额外DDNS脚本
git clone --depth 1 https://github.com/small-5/ddns-scripts-dnspod    package/lean/ddns-scripts_dnspod
git clone --depth 1 https://github.com/small-5/ddns-scripts-aliyun    package/lean/ddns-scripts_aliyun

# CPU主频
if [ "${MYOPENWRTTARGET}" = 'R2S' ] ; then
  svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/luci-app-cpufreq package/lean/luci-app-cpufreq
  cp -f ../PRECONFS/cpufreq ./package/lean/luci-app-cpufreq/root/etc/config/cpufreq
fi
# Zerotier
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/luci-app-zerotier  package/lean/luci-app-zerotier
rm -rf ./feeds/packages/net/zerotier/files/etc/init.d/zerotier
# 翻译及部分功能优化
if [ "${MYOPENWRTTARGET}" != 'R2S' ] ; then
  sed -i '/openssl\.cnf/d' ../PATCH/duplicate/addition-trans-zh/files/zzz-default-settings
  sed -i '/upnp/Id'        ../PATCH/duplicate/addition-trans-zh/files/zzz-default-settings
fi
cp -rf ../PATCH/duplicate/addition-trans-zh ./package/lean/lean-translate
# 给root用户添加vim和screen的配置文件
mkdir -p                                    ./package/base-files/files/root/
cp -f ../PRECONFS/vimrc                     ./package/base-files/files/root/.vimrc
cp -f ../PRECONFS/screenrc                  ./package/base-files/files/root/.screenrc

### 4. 最后的收尾工作 ###
# 最大连接
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# crypto相关
if [ "${MYOPENWRTTARGET}" = 'R2S' ] ; then
echo '
CONFIG_ARM64_CRYPTO=y
CONFIG_ARM_PSCI_CPUIDLE_DOMAIN=y
CONFIG_ARM_PSCI_FW=y
CONFIG_ARM_RK3328_DMC_DEVFREQ=y
CONFIG_CRYPTO_AES_ARM64=y
CONFIG_CRYPTO_AES_ARM64_BS=y
CONFIG_CRYPTO_AES_ARM64_CE=y
CONFIG_CRYPTO_AES_ARM64_CE_BLK=y
CONFIG_CRYPTO_AES_ARM64_CE_CCM=y
CONFIG_CRYPTO_AES_ARM64_NEON_BLK=y
CONFIG_CRYPTO_CHACHA20_NEON=y
# CONFIG_CRYPTO_CRCT10DIF_ARM64_CE is not set
CONFIG_CRYPTO_GHASH_ARM64_CE=y
CONFIG_CRYPTO_NHPOLY1305_NEON=y
CONFIG_CRYPTO_POLY1305_NEON=y
CONFIG_CRYPTO_SHA1_ARM64_CE=y
CONFIG_CRYPTO_SHA2_ARM64_CE=y
CONFIG_CRYPTO_SHA256_ARM64=y
CONFIG_CRYPTO_SHA3_ARM64=y
CONFIG_CRYPTO_SHA512_ARM64=y
# CONFIG_CRYPTO_SHA512_ARM64_CE is not set
CONFIG_CRYPTO_SM3_ARM64_CE=y
CONFIG_CRYPTO_SM4_ARM64_CE=y
' >> ./target/linux/rockchip/armv8/config-5.4
fi
# 删除已有配置
rm -rf .config
# 删除.svn目录
find ./ -type d -name '.svn' -print0 | xargs -0 -s1024 /bin/rm -rf
unalias wget
exit 0
