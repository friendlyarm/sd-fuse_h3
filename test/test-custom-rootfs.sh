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
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/rootfs/rootfs-friendlycore-focal.tgz
tar xzf rootfs-friendlycore-focal.tgz
echo hello > friendlycore-focal/rootfs/root/welcome.txt
(cd friendlycore-focal/rootfs/root/ && {
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-focal-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh friendlycore-focal/rootfs friendlycore-focal
sudo ./mk-sd-image.sh friendlycore-focal
sudo ./mk-emmc-image.sh friendlycore-focal
