#!/bin/bash
# 如果没有环境变量或无效，则默认R2S版本
[ -n "$MYOPENWRTTARGET" ] && [ -d ../SEED/$MYOPENWRTTARGET ] || MYOPENWRTTARGET='R2S'
echo "==> Now packaging: $MYOPENWRTTARGET"

case $MYOPENWRTTARGET in
  R2S)
    /bin/ls | grep -v -E '(squashfs|manifest)' | xargs -s1024 /bin/rm -rf
    ;;
  x86)
    /bin/ls | grep -v -E '(combined|manifest)' | xargs -s1024 /bin/rm -rf
    ;;
esac
gzip -d *.gz
gzip --best --keep *.img
sha256sum openwrt* | tee sha256_$(date "+%Y%m%d").hash
md5sum    openwrt* | tee    md5_$(date "+%Y%m%d").hash
rm -f *.img
exit 0
