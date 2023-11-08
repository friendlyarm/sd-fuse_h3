#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243
KERNEL_URL=https://github.com/friendlyarm/linux
KERNEL_BRANCH=sunxi-4.14.y

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
    HTTP_SERVER=127.0.0.1
    KERNEL_URL=git@192.168.1.5:/allwinner/linux-sunxi.git
    KERNEL_BRANCH=sunxi-4.14.y-devel
fi

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
