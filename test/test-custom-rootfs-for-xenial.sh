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
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/rootfs/rootfs-friendlycore.tgz
tar xzf rootfs-friendlycore.tgz
echo hello > friendlycore/rootfs/root/welcome.txt
(cd friendlycore/rootfs/root/ && {
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh friendlycore/rootfs friendlycore
sudo ./mk-sd-image.sh friendlycore
sudo ./mk-emmc-image.sh friendlycore
