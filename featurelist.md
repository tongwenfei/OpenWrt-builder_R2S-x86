## 功能与特性

### 重要事项
* 添加`shadow-utils`组件（用于方便新建用户），导致管理页面上的`更改密码`功能失效。 
请使用SSH工具，使用空密码登陆后，执行`passwd`命令并根据提示设置密码。
* 相对于FriendlyWrt的默认设计，本固件已交换WAN/LAN口。  
现在LAN口绑定在远离电源接口的那一个RJ45上。
* 本固件对所有R2S设备产生相同的MAC地址。如果您在同一个子网内使用多个R2S设备，请务必自行修改MAC地址设置，该子网内每个设备的MAC地址都唯一。

### 安全性
* 防火墙设置为默认拒绝来自WAN口入站数据和转发。
* 未安装ttyd组件（网页终端）。因为该组件默认开发端口，且不使用HTTPS；同时该组件默认免密码root身份登录到shell。  
同样，dockerman组件也未启用ttyd支持。
* 固件默认密码为空，建议刷机后尽快更改密码。
* Dropbear默认监听了所有接口，建议刷机后尽快更改为只监听LAN口。

### 常用功能
|  |  |  |  |  |  |
| :---: | :---: | :---: | :---: | :---: | :---: |
| NetData监控 | WireGuard | 释放内存 | 定时重启 | ZeroTier | Adbyby反广告 |
| SSRP | OpenClash | 动态DNS | SmartDNS | 硬盘休眠 | WOL网络唤醒 |
| uHTTPd配置 | Samba4 | Aria2 | UPnP配置 | Docker | IP/MAC绑定 |
| SQM | 带宽监控 | BBR (1) | FullCone NAT (2) | Flow Offloading (2) | SFE Offloading (2) |

1. BBR已默认启用。  
2. SFE Offloading已默认启用，其设置在防火墙设置页面中；FullCone NAT和Flow Offloading需要在防火墙设置中手动开启。但是，SFE Offloading和Flow Offloading只能**二选一**，**不能同时开启**。  
3. FTP支持由vsftpd-tls提供。没用图形界面，须使用命令行手工配置。建议开启TLS以提高安全性。  
4. 以下组件在本固件中不包含：  
ttyd（网页终端）、单线/多线多拨、KMS服务器、访问时间控制、WiFi排程、beardropper（SSH公网访问限制）、应用过滤、三代壳OLED程序、Server酱、网易云音乐解锁、USB-打印机、迅雷快鸟、pandownload-fake-server、frpc/frps内网穿透、OpenVPN、京东自动签到、Transmission、qBittorrent。

### 命令行特性
* 添加`shadow-utils`组件，便于配置文件共享时新建用户。
* SSH客户端由OpenSSH提供（而不是Dropbear），提供更标准的SSH连接体验。（服务端仍然是Dropbear）
* F2FS、EXT4、FAT32、BTRFS文件系统支持。EXT4支持acl和attr。
* Python3、Perl、Node.js解释型语言支持。C语言支持由GCC和make提供。
* Git版本控制工具。
* `curl`和`wget`两大常用工具。
* 由openssh-sftp-server提供SFTP协议文件传输功能。由lrzsz提供终端内小文件传输功能。由openssh-keygen提供SSH密钥对生成。
* 常用命令行工具：bc、file、htop、lsof、nohup、pv、timeout、tree、xxd。
* 文本编辑器：nano、vim。
* 终端复用工具：screen、tmux。
* 网络相关工具：dig、ethtool、host、ifstat、iftop、iperf3、ncat、nmap、nping、ss。
* 压缩工具：zstd。
* 文件同步工具：rsync。
* 密码学工具：GnuPG。
* 压力测试工具：stress。
* 硬盘自检工具：smartmontools。
* 磁盘分区工具：fdisk、cfdisk（用于MBR分区表）、gdisk、cgdisk（用于GPT分区表）。
* 其他工具：oath-toolkit、qrencode、sqlite3-cli。

### OpneSSL
* 支持签发自签名证书。

### 无线网卡
* 理论上支持部分USB无线网卡，未测试。

### Dcoker相关
* dockerman组件也未启用ttyd支持，因此网页上“连接到容器”功能不可用。请使用命令行相关操作替代。
* Docker默认开机自动启动。对于不使用Docker的用户可能在性能方面有负面影响，建议在管理页面中禁用Docker。
* 由于Docker存在，对SSRP和Clash的UDP转发有影响。如果用户有通过SSRP或Clash代理玩外服游戏（或其他依靠UDP通信的应用需要经过代理）的需求，请勿选择此版本。

### 三代壳OLED相关
* 未安装OLED的luci-app和对于的程序。但包含了其依赖的i2c-tools软件包。需要OLED功能的用户，自行寻找/选择适合的软件包安装即可。也可从源代码，利用本固件自带的GCC编译。