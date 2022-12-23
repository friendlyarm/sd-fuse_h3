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
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-focal_4.14_armhf.tgz
tar xzf friendlycore-focal_4.14_armhf.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/eflasher.tgz
tar xzf eflasher.tgz

# make big file
fallocate -l 5G friendlycore-focal_4.14_armhf/rootfs.img

# calc image size
IMG_SIZE=`du -s -B 1 friendlycore-focal_4.14_armhf/rootfs.img | cut -f1`

# re-gen parameter.txt
./tools/generate-partmap-txt.sh ${IMG_SIZE} friendlycore-focal_4.14_armhf h3

sudo ./mk-sd-image.sh friendlycore-focal_4.14_armhf
sudo ./mk-emmc-image.sh friendlycore-focal_4.14_armhf
