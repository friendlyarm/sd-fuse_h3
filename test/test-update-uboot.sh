#!/bin/bash
set -eu

# HTTP_SERVER=112.124.9.243
HTTP_SERVER=192.168.1.9

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_h3
cd sd-fuse_h3
wget http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-xenial_4.14_armhf.tgz
tar xzf friendlycore-xenial_4.14_armhf.tgz

git clone https://github.com/friendlyarm/u-boot --depth 1 -b sunxi-v2017.x uboot-h3

UBOOT_SRC=$PWD/uboot-h3 ./build-uboot.sh friendlycore-xenial_4.14_armhf
sudo ./mk-sd-image.sh friendlycore-xenial_4.14_armhf
