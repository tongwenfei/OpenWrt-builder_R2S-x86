## 清盘刷机脚本使用说明
### 1. 获取脚本
```bash
mkdir /tmp/uploads
cd /tmp/uploads
curl --proto '=https' --tlsv1.2 -sSf -O \
     https://cdn.jsdelivr.net/gh/KaneGreen/OpenWrt-builder_R2S-x86@master/clean_flash.sh
```
### 2. 上传固件
使用 sftp 工具或 scp 命令将固件上传到 `/tmp/uploads` 目录下。  
支持 IMG 镜像文件或 GZ 压缩包格式。  
文件名以 `openwrt` 开头，以 `.img` 或 `.img.gz` 结尾（注意：大小写敏感）。

如果有 MD5 或 SHA256 的校验文件，请也上传到 `/tmp/uploads` 目录下。  
MD5 校验文件的文件名称格式为 `md5_????????.hash`。  
SHA256 校验文件的文件名称格式为 `sha256_????????.hash`。
### 3. 执行刷机
#### 3.1 不执行清盘
若不打算对储存卡进行“写零”处理，请执行下面的命令。
```bash
/bin/bash /tmp/uploads/clean_flash.sh
```
#### 3.2 执行清盘
“写零”清盘适合于固件变动内容比较大的情况下使用，这种方法可能解决跨版本刷机时由于磁盘储存残留导致的奇特 BUG。  
但是，此过程通常需要消耗较长时间。
```bash
CLEANDISK=1 /bin/bash /tmp/uploads/clean_flash.sh
```
注意 `CLEANDISK` 环境变量的值，上面的例子中是 `1`，即只对储存卡上前 1GB 的空间做“写零”处理。  
同理若为 `2`，则前 2GB；若为 `3`，则前 3GB；若为 `4`，则前 4GB；以此类推。  
但是，若为 `0` 或其他非数字值，则对整个储存卡上的所有空间做“写零”处理。但这可能需要消耗很长时间。  
例如下面的命令将全清整个储存卡。
```bash
CLEANDISK=true /bin/bash /tmp/uploads/clean_flash.sh
```
