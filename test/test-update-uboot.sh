#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
       HTTP_SERVER=127.0.0.1
fi

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_h3
cd sd-fuse_h3
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-focal-images.tgz
tar xzf friendlycore-focal-images.tgz

git clone https://github.com/friendlyarm/u-boot --depth 1 -b sunxi-v2017.x uboot-h3

UBOOT_SRC=$PWD/uboot-h3 ./build-uboot.sh friendlycore-focal
sudo ./mk-sd-image.sh friendlycore-focal
