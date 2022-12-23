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
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-xenial_4.14_armhf.tgz
tar xzf friendlycore-xenial_4.14_armhf.tgz

# git clone https://github.com/friendlyarm/linux -b sunxi-4.14.y --depth 1 kernel-h3
git clone git@192.168.1.5:/allwinner/linux-sunxi.git --depth 1 -b sunxi-4.14.y-devel kernel-h3

KERNEL_SRC=$PWD/kernel-h3 ./build-kernel.sh friendlycore-xenial_4.14_armhf
sudo ./mk-sd-image.sh friendlycore-xenial_4.14_armhf
