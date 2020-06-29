## 功能与特性

### 重大改变
* 添加`shadow-utils`组件（用于方便新建用户），导致管理页面上的`更改密码`功能失效。 
请使用SSH工具，使用空密码登陆后，执行`passwd`命令并根据提示设置密码。
* 相对于FriendlyWrt的默认设计，本固件已交换WAN/LAN口。  
现在LAN口绑定在远离电源接口的那一个RJ45上。

### 安全性
* 防火墙设置为默认拒绝来自WAN口入站数据和转发。
* 未安装ttyd组件（网页终端）。因为该组件默认开发端口，且不使用HTTPS；同时该组件默认免密码root身份登录到shell。  
同样，dockerman组件也未启用ttyd支持。
* 固件默认密码为空，建议刷机后尽快更改密码。
* Dropbear默认监听了所有接口，建议刷机后尽快更改为只监听LAN口。

### 功能列表
|:---:|:---:|:---:|:---:|:---:|:---:|
| NetData监控 | WireGuard | 释放内存 | 定时重启 | ZeroTier | Adbyby反广告 |
| SSRP | OpenClash | 动态DNS | SmartDNS | 硬盘休眠 | WOL网络唤醒 |
|uHTTPd配置 | Samba4 | Aria2 | UPnP配置 | Docker | IP/MAC绑定 |
|SQM | 带宽监控 | BBR | FullCone NAT | Flow Offloading |  |

### Dcoker相关
* dockerman组件也未启用ttyd支持，因此网页上“连接到容器”功能不可用。请使用命令行相关操作替代。
* Docker默认开机自动启动。对于不使用Docker的用户可能在性能方面有负面影响，建议在管理页面中禁用Docker。
* 由于Docker存在，对SSRP和Clash的UDP转发有影响。如果用户有通过SSRP或Clash代理玩外服游戏（或其他依靠UDP通信的应用需要经过代理）的需求，请勿选择此版本。