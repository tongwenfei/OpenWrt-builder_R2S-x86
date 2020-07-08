## 变更历史
### 2020/07/08 build 43
* 更新[上游](https://github.com/project-openwrt/R2S-OpenWrt/tree/623dd36c218e872c08e5663faea02975ea626eea)。
### 2020/07/06 build 42
* 撤销zstd 1.4.5更新。
* 更新[上游](https://github.com/project-openwrt/R2S-OpenWrt/tree/dd4a01dab3a211dbb97fbfdc48371d549b44de91)。
### 2020/07/06 build 41
编译失败，但变更并未撤销，下一次编译将包含此版内容。
* 恢复OpenSSL配置，尝试修复前两次编译失败。
### 2020/07/06 build 40
编译失败，但变更并未撤销，下一次编译将包含此版内容。
* ROOTFS调整为448MB。
### 2020/07/06 build 39
编译失败，但变更并未撤销，下一次编译将包含此版内容。
* 移除Docker、SmartDNS相关组件。
* 更新[上游](https://github.com/project-openwrt/R2S-OpenWrt/tree/a820f8284ce9544d9adbc031db544fb81c8e6c29)。
### 2020/07/05 build 38
* 内核更新至`5.4.50`。
* 更新[上游](https://github.com/project-openwrt/R2S-OpenWrt/tree/5bbd97c1ba3fe4f4a21478fd358f9fae06eb0045)。
### 2020/07/04 build 37
* Python3版本退回至3.7.7。待OpenWrt-19.07源中的版本修复后再跟进。
* Python3添加pip包管理器。
* SSRP更新为`179-3`；v2ray-core更新至`4.25.1`。
* SFE功能已经基本稳定。
* 更新[上游](https://github.com/project-openwrt/R2S-OpenWrt/tree/8a26c577e84adf82cf530bb82200da965816b36e)。
### 2020/07/04 build 36
编译失败。撤销变更。
* 尝试修复Python3版本更新3.7.8编译错误。
### 2020/07/03 build 35
编译失败。尝试其他方法。
* 尝试修复Python3版本更新3.7.8编译错误。
### 2020/07/03 build 34
SFE启动脚本稳定性原因，撤回本版。
* Python3版本退回至3.7.7。
### 2020/07/03 build 33
编译失败。
* 撤销更新Python版本，尝试修复编译失败的问题。
### 2020/07/03 build 32
编译失败。但变更并未撤销，下一次编译将包含此版内容。
* 尝试修复编译失败的问题。
### 2020/07/03 build 31
编译失败。但变更并未撤销，下一次编译将包含此版内容。
* 添加SFE。
* 更新[上游](https://github.com/project-openwrt/R2S-OpenWrt/tree/30ab6b2f096682cc1ef7e2792b46479c5fd438b5)。
### 2020/07/02 build 30
编译失败。但变更并未撤销，下一次编译将包含此版内容。
* 更新Python版本以尝试修复编译失败的问题。
### 2020/07/02 build 29
编译失败。但变更并未撤销，下一次编译将包含此版内容。
* 更新[上游](https://github.com/project-openwrt/R2S-OpenWrt/tree/2e828fe22a8f16620a555ba6255d642615476d70)。
### 2020/07/02 build 28
编译失败。但变更并未撤销，下一次编译将包含此版内容。
* 更新[上游](https://github.com/project-openwrt/R2S-OpenWrt/tree/9f54dc69860da0b9387d67255f3605571c6a0d71)。
### 2020/06/29 build 27
* 更新[上游](https://github.com/QiuSimons/R2S-OpenWrt/tree/d7f6ecd9862d52e05b5047a9db809580049527c4)。
* 添加命令行工具gdisk、cgdisk、dosfstools。
### 2020/06/28 build 26
* 更新[上游](https://github.com/QiuSimons/R2S-OpenWrt/tree/9d02e66fcfdd16f0b96ed38149047f6b8cfbcf29)。
### 2020/06/24 build 25
* 更新[上游](https://github.com/QiuSimons/R2S-OpenWrt/tree/a9ef544c7c5f986c43707dd3c25806ded96aea27)。
* 内核更新至`5.4.48`。
### 2020/06/22 build 24
* 更新[上游](https://github.com/QiuSimons/R2S-OpenWrt/tree/b887731d111135ab36e9c40a2363274e1f3f3069)。
* v2ray-core更新至`4.25.0`。
* 加入了GCC编译器。
### 2020/06/20 build 23
* 移除XFS文件系统相关支持。
* 更新[上游](https://github.com/QiuSimons/R2S-OpenWrt/tree/4c63f15bdf78780feb3bc5ae11cde1b6d0cf1031)。
* 改进对Docker的支持。
### 2020/06/19 build 22
* 移除构建过程中download的步骤。
### 2020/06/18 build 21
* 由于build 20实验性构建实际无效，已撤销更改。
### 2020/06/18 build 20
* 实验性构建：尝试启用所有Generally Necessary和常用见的Optional Features。
### 2020/06/18 build 19
* 更新[上游](https://github.com/QiuSimons/R2S-OpenWrt/tree/4dc98c9b7a745cb25f56f679ceae8af23d164f73)。
* 内核更新至`5.4.46`。
### 2020/06/14 build 18
* 来自[上游](https://github.com/QiuSimons/R2S-OpenWrt/tree/3954f46c35331b0b6837c073961281a728187ed8)的重要变更：取消irqbalance，改为手动绑定软中断的CPU亲和力，以提升高负载情况下的性能表现。
* SSRP更新为`179-1`。
### 2020/06/14 build 17
* 移除未生效的OPENSSL_ENGINE_BUILTIN。
### 2020/06/13 build 16
* SSRP更新为`178-7`，trojan更新至`1.16.0`，v2ray-core更新至`4.24.2`。
### 2020/06/10 build 15
* 内核更新至`5.4.45`。
* SSRP更新为`178-6`。
### 2020/06/07 build 14
* 为Node.js添加npm包管理器。
* Node.js更新为`v12.16.1`版本。
### 2020/06/07 build 13
* 移除subversion-client。
* 添加openssh-client（标准的SSH客户端；服务端仍保持为dropbear不变）及相关工具。
* 添加dropbearconvert用于将SSH格式密钥转换为dropbear的格式。
* 为git添加http(s)协议支持。
* 添加Node.js语言支持。
### 2020/06/07 build 12
* 添加badblocks坏道扫描工具。
* 扩大ROOTFS分区大小。
* git依赖于perl，所以perl解释器不能移除。
### 2020/06/06 build 11
空间不足导致编译失败。但变更并未撤销，下一次编译将包含此版内容。
* 添加git和subversion-client两个版本控制工具。
* 添加perl解释器。
### 2020/06/06 build 10
* 更新[上游](https://github.com/QiuSimons/R2S-OpenWrt/tree/57eeb22a07104f5537faa3b4764b8bd5811956ef)。
* 为dnsmasq添加filter AAAA功能。
* 添加sha1sum、sha512sum、shred、rsync等命令行工具。
### 2020/06/04 build 09
* 更新[上游](https://github.com/QiuSimons/R2S-OpenWrt/tree/3c6cc906d322ed6608c0cf83e1319f9f74356f31)。
* 添加主题luci-theme-argo。
* 内核更新至`5.4.43`。
### 2020/06/01 build 08
* v2ray-core更新至`4.23.2`，修复[tls相关问题](https://github.com/v2ray/discussion/issues/704)。
* 出于兼容性考虑，移除luci-theme-openwrt主题。现在默认主题是luci-theme-material。
### 2020/05/31 build 07
* AdGuard Home改为Adbyby-plus。
* 移除beardropper。
* 添加asix USB网卡支持。
### 2020/05/28 build 06
* SSRP更新为`178-5`。
### 2020/05/27 build 05
* 添加主题luci-theme-openwrt。
### 2020/05/27 build 04
已取消。但变更并未撤销，下一次编译将包含此版内容。
* 再次调整ROOTFS分区大小。
### 2020/05/27 build 03
* 重新编译build 02。
### 2020/05/27 build 02
由于分配的空间不足，编译失败。但变更并未撤销，下一次编译将包含此版内容。
* 出于安全考虑，移除ttyd以及dockerman的ttyd部分。
### 2020/05/26 build 01
* 首次编译。
