# This is the experimental branch!
此分支包含测试性内容！

## R2S 基于原生 OpenWRT 的固件编译脚本 (AS IS, NO WARRANTY!!!)
### 请勿用于商业用途!!!
**同时也包含了 x86_64 版本**

### 注意事项：
1. 登陆 IP：`192.168.1.1`，密码：无。

2. R2S 版 OpenWrt 内置升级可用。

3. R2S 版 build 66（2020年8月1日）及以后的固件，继续交换 LAN WAN 网口，即和原厂接口定义相反（LAN 口是远离电源接口的那一个 RJ45 接口）。

4. 遇到上不了网的，请自行排查自己的 IPv6 连接情况，或禁用 IPv6（同时禁用 WAN 和 LAN 的 IPv6）（默认已关闭ipv6的dns解析，手动可以在DHCP/DNS里的高级设置中调整）

5. R2S 版 sys 灯引导时闪烁，启动后常亮，也是上游的设定，有疑问请联系 OpenWrt 官方社区。

### 版本信息：
LUCI版本：master（当日最新）

其他模块版本：master（当日最新）

### 特性及功能：
1. O3 优化级别。R2S 版核心频率 1.5GHz，SquashFS 格式。x86 版 EXT4 格式，非 UEFI 版本。

2. 内置一款主题，包含 SSRP，OpenClash，AdGuard Home，SQM，网络唤醒，DDNS，UPNP，FullCone（默认开启），流量分载（防火墙中手动开启），BBR（默认开启）。  
[完整功能列表](./featurelist.md)

3. Github Actions 里面的编译结果包含 SHA256 哈希校验和 MD5 哈希校验文件。同样的内容也会显示在 Actions 的编译日志的 `Cleaning and hashing` 步骤（倒数第四步）里。**请注意核对和校验固件文件的完整性！**

4. [清盘刷机教程](./howto_cleanflash.md)  [变更日志](./CHANGELOG.md)

### 三代壳 OLED 相关
R2S 版未编译安装 OLED 的 luci-app，有需要者自行寻找软件包安装。
x86 版不支持此功能。

### 感谢
* [QiuSimons](https://github.com/QiuSimons/)
* [quintus-lab](https://github.com/quintus-lab/)
* [CTCGFW](https://github.com/immortalwrt/immortalwrt)
* [coolsnowwolf](https://github.com/coolsnowwolf)
* [Lienol](https://github.com/Lienol)
* [NoTengoBattery](https://github.com/NoTengoBattery)
* 以及其他所有曾为 R2S 做出努力的贡献者们。
