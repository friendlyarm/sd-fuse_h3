#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

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
