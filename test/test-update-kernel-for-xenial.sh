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
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-images.tgz
tar xzf friendlycore-images.tgz

git clone https://github.com/friendlyarm/linux -b sunxi-4.14.y --depth 1 kernel-h3

KERNEL_SRC=$PWD/kernel-h3 ./build-kernel.sh friendlycore
sudo ./mk-sd-image.sh friendlycore
