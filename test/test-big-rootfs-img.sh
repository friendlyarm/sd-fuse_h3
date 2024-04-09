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
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-focal-images.tgz
tar xzf friendlycore-focal-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

# make big file
fallocate -l 5G friendlycore-focal/rootfs.img

# calc image size
IMG_SIZE=`du -s -B 1 friendlycore-focal/rootfs.img | cut -f1`

# re-gen parameter.txt
./tools/generate-partmap-txt.sh ${IMG_SIZE} friendlycore-focal h3

sudo ./mk-sd-image.sh friendlycore-focal
sudo ./mk-emmc-image.sh friendlycore-focal
