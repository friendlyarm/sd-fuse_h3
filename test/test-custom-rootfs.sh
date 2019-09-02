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
wget http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/eflasher.tgz
tar xzf eflasher.tgz
wget http://${HTTP_SERVER}/dvdfiles/H3/rootfs/rootfs_friendlycore_4.14.tgz
tar xzf rootfs_friendlycore_4.14.tgz -C friendlycore-xenial_4.14_armhf
echo hello > friendlycore-xenial_4.14_armhf/rootfs/root/welcome.txt
./build-rootfs-img.sh friendlycore-xenial_4.14_armhf/rootfs friendlycore-xenial_4.14_armhf/rootfs.img
sudo ./mk-sd-image.sh friendlycore-xenial_4.14_armhf
sudo ./mk-emmc-image.sh friendlycore-xenial_4.14_armhf
