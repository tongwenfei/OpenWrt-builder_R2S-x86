#!/bin/bash
/bin/ls -AFhlt
rm -rf `/bin/ls | grep -v -E '(squashfs|manifest)'`
gzip -d *.gz
gzip --best --keep *.img
sha256sum openwrt* | tee sha256_$(date "+%Y%m%d").hash
md5sum    openwrt* | tee    md5_$(date "+%Y%m%d").hash
rm -f *.img
exit 0
