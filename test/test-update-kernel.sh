#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243
KERNEL_URL=https://github.com/friendlyarm/linux
KERNEL_BRANCH=sunxi-4.14.y

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_h3
cd sd-fuse_h3
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-focal-images.tgz
tar xzf friendlycore-focal-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel-h3

KERNEL_SRC=$PWD/kernel-h3 ./build-kernel.sh friendlycore-focal
sudo ./mk-sd-image.sh friendlycore-focal
sudo ./mk-emmc-image.sh friendlycore-focal
