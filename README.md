# This is the master branch!
This repository is going to keep using the term "**master**". It will **never change**.
I **refuse** to switch to "main".

## R2S 基于原生 OpenWRT 的固件 (AS IS, NO WARRANTY!!!)

### 发布地址：
（可能会翻车，风险自担，需要登录 GitHub 账号后才能下载，不提供任何形式的技术支持）  
https://github.com/KaneGreen/R2S-OpenWrt/actions  
![OpenWrt for R2S](https://github.com/KaneGreen/R2S-OpenWrt/workflows/OpenWrt%20for%20R2S/badge.svg?branch=master&event=push)

建议对照[变更日志](./CHANGELOG.md)确认版本之间的变化。

### 本地一键编译命令：
安装依赖（测试编译环境为 Ubuntu 20.10）：
```shell
sudo -E apt-get install -y build-essential rsync asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib g++-multilib p7zip p7zip-full msmtp libssl-dev texinfo libreadline-dev libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint ccache curl wget vim nano python python3 python-pip python3-pip python-ply python3-ply haveged lrzsz device-tree-compiler scons
wget -O - https://raw.githubusercontent.com/friendlyarm/build-env-on-ubuntu-bionic/master/install.sh | bash
```
为你的 Git 设置用户名和邮箱（已经配置过的请跳过）：
```shell
git config --global user.name "YourName" && git config --global user.email "noreply@example.com"
```
一键编译：
```shell
git clone https://github.com/KaneGreen/R2S-OpenWrt.git && cd R2S-OpenWrt && bash onekeyr2s.sh
```
（注意：本仓库对该脚本的维护较为消极，可能需要更具实际情况yml文件具体内容修改后才能使用。）
### 注意事项：
1. 登陆 IP：`192.168.1.1`，密码：无。

2. OpenWrt 内置升级可用

3. build 66（8月1日）及以后的固件，继续交换 LAN WAN 网口，即和原厂接口定义相反（LAN 口是远离电源接口的那一个 RJ45 接口）。

4. 遇到上不了网的，请自行排查自己的 IPv6 连接情况，或禁用 IPv6（同时禁用 WAN 和 LAN 的 IPv6）（默认已关闭ipv6的dns解析，手动可以在DHCP/DNS里的高级设置中调整）

5. sys 灯引导时闪烁，启动后常亮，也是上游的设定，有疑问请联系 OpenWrt 官方社区。

### 版本信息：
其他模块版本：SNAPSHOT（当日最新）

LUCI版本：19.07（当日最新）

### 特性及功能：
1. O2 编译，核心频率 1.5GHz。

2. 内置四款主题，包含 SSRP，OpenClash，PASSWALL，AdGuard Home，SQM，网络唤醒，DDNS，UPNP，FullCone（默认开启），流量分载（软件或 SFE，二选一，防火墙中手动开启），BBR（默认开启）。  
[完整功能列表](./featurelist.md)

3. Github Actions 里面的编译结果包含 SHA256 哈希校验和 MD5 哈希校验文件。同样的内容也会显示在 Actions 的编译日志的 `Cleaning and hashing` 步骤（倒数第四步）里。**请注意核对和校验固件文件的完整性！**

4. [清盘刷机教程](./howto_cleanflash.md)  [变更日志](./CHANGELOG.md)

### 其他信息
由于添加了 `shadow-utils`组件，管理页面上的 `更改密码` 功能失效。  
请使用 SSH 空密码登陆后，执行 `passwd` 命令并根据提示设置密码。

### 三代壳 OLED 相关
未编译安装 OLED 的 luci-app ，有需要者自行寻找软件包安装，或者下载源码后使用本固件自带的 gcc 和 make 编译。

### 感谢
* [QiuSimons](https://github.com/QiuSimons/)
* [quintus-lab](https://github.com/quintus-lab/)
* [CTCGFW](https://github.com/project-openwrt/openwrt)
* 以及其他所有曾为 R2S 做出努力的贡献者们。
