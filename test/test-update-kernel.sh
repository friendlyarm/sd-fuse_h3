#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
       HTTP_SERVER=192.168.1.9
fi

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_h3
cd sd-fuse_h3
wget http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-focal_4.14_armhf.tgz
tar xzf friendlycore-focal_4.14_armhf.tgz

# git clone https://github.com/friendlyarm/linux -b sunxi-4.14.y --depth 1 kernel-h3
git clone git@192.168.1.5:/allwinner/linux-sunxi.git --depth 1 -b sunxi-4.14.y-devel kernel-h3

KERNEL_SRC=$PWD/kernel-h3 ./build-kernel.sh friendlycore-focal_4.14_armhf
sudo ./mk-sd-image.sh friendlycore-focal_4.14_armhf
