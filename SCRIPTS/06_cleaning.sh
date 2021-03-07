#!/bin/bash
case ${MYOPENWRTTARGET} in
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
