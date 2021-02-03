#!/bin/bash
function color_echo {
    local prefixstr="$1"
    case ${prefixstr,,} in
      red)
        prefixstr='\033[31m'
        ;;
      green)
        prefixstr='\033[32m'
        ;;
      yellow)
        prefixstr='\033[33m'
        ;;
      boldred)
        prefixstr='\033[1;31m'
        ;;
      boldgreen)
        prefixstr='\033[1;32m'
        ;;
      boldyellow)
        prefixstr='\033[1;33m'
        ;;
    esac
    echo -e "${prefixstr}$2\033[00m"
}

color_echo BOLDred '您确认要开始刷机吗？'
color_echo red '此操作将清空您的MicroSD卡上的数据。'
color_echo red '如果您打算放弃操作，请在20秒内按下Ctrl+C组合键。'
( set -x ; sleep 20 )
color_echo green '已启动刷机流程...\n请不要操作键盘等输入设备，并保持电源接通。'
cd /tmp
[ -d "uploads" ] || mkdir uploads && cd uploads
type shred >/dev/null 2>&1
    if [ $? -eq 0 ] ; then
        cp -f $(which shred) ./
    fi
cp -f $(which busybox) ./
if [ -f openwrt*.img ] ; then
    color_echo green "检测到IMG文件 $(ls openwrt*.img)"
    if [ -f sha256_????????.hash ] ; then
        grep ".img$" sha256_????????.hash > sha256hash
        sha256sum -c sha256hash
        if [ $? -eq 0 ] ; then
            color_echo green 'SHA256校验通过'
            rm -f sha256hash
        else
            color_echo BOLDred 'SHA256校验失败'
            exit 129
        fi
    else
        color_echo yellow '跳过SHA256校验'
    fi
    if [ -f md5_????????.hash ] ; then
        grep ".img$" md5_????????.hash > md5hash
        md5sum -c md5hash
        if [ $? -eq 0 ] ; then
            color_echo green 'MD5校验通过'
            rm -f md5hash
        else
            color_echo BOLDred 'MD5校验失败'
            exit 130
        fi
    else
        color_echo yellow '跳过MD5校验'
    fi
    mv openwrt*.img firmware.img
elif [ -f openwrt*.img.gz ] ; then
    color_echo green "检测到GZ文件 $(ls openwrt*.img.gz)"
    gzip -t openwrt*.img.gz
    if [ $? -eq 0 ] ; then
        color_echo green '压缩包测试通过'
    else
        color_echo red '压缩包可能已经损坏'
        exit 131
    fi
    if [ -f sha256_????????.hash ] ; then
        grep ".img.gz$" sha256_????????.hash > sha256hash
        sha256sum -c sha256hash
        if [ $? -eq 0 ] ; then
            color_echo green 'SHA256校验通过'
            rm -f sha256hash
        else
            color_echo BOLDred 'SHA256校验失败'
            exit 129
        fi
    else
        color_echo yellow '跳过SHA256校验'
    fi
    if [ -f md5_????????.hash ] ; then
        grep ".img.gz$" md5_????????.hash > md5hash
        md5sum -c md5hash
        if [ $? -eq 0 ] ; then
            color_echo green 'MD5校验通过'
            rm -f md5hash
        else
            color_echo BOLDred 'MD5校验失败'
            exit 130
        fi
    else
        color_echo yellow '跳过MD5校验'
    fi
    mv openwrt*.img.gz firmware.img.gz
else
    color_echo BOLDred '没有找到受支持的刷机包'
    exit 132
fi
echo 1 > /proc/sys/kernel/sysrq
echo u > /proc/sysrq-trigger
if [ -n "$CLEANDISK" ] ; then
    color_echo green '开始擦除MicroSD卡：通常这将消耗很长时间。'
    if [[ $CLEANDISK =~ ^[1-9][0-9]*$ ]] ; then
        DDARGU=$((256 * $CLEANDISK))
        ./busybox dd conv=fsync bs=8M count=$DDARGU if=/dev/zero of=/dev/mmcblk0
    else
        if [ -f "shred" ] ; then
            ./shred -n 0 -z -v /dev/mmcblk0
        else
            ./busybox dd conv=fsync bs=8M if=/dev/zero of=/dev/mmcblk0
        fi
    fi
    color_echo green '擦除完成'
fi
color_echo green '开始写入数据...'
color_echo BOLDyellow '请不要操作键盘等输入设备，并保持电源接通。\n切勿中断此过程。'
if [ -f firmware.img ] ; then
    ./busybox dd conv=fsync bs=8M if=/tmp/uploads/firmware.img of=/dev/mmcblk0
elif [ -f firmware.img.gz ] ; then
    ./busybox gzip -dc firmware.img.gz | ./busybox dd conv=fsync bs=8M of=/dev/mmcblk0
fi
color_echo green '刷机完成，稍后将执行重启...'
./busybox sleep 5
color_echo BOLDgreen '开始重启...'
echo b > /proc/sysrq-trigger
