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
wget http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/eflasher.tgz
tar xzf eflasher.tgz
wget http://${HTTP_SERVER}/dvdfiles/H3/rootfs/rootfs_friendlycore-focal_4.14.tgz
tar xzf rootfs_friendlycore-focal_4.14.tgz -C friendlycore-focal_4.14_armhf
echo hello > friendlycore-focal_4.14_armhf/rootfs/root/welcome.txt
(cd friendlycore-focal_4.14_armhf/rootfs/root/ && {
	wget http://${HTTP_SERVER}/dvdfiles/H3/images-for-eflasher/friendlycore-focal_4.14_armhf.tgz -O deleteme.tgz
});
./build-rootfs-img.sh friendlycore-focal_4.14_armhf/rootfs friendlycore-focal_4.14_armhf
sudo ./mk-sd-image.sh friendlycore-focal_4.14_armhf
sudo ./mk-emmc-image.sh friendlycore-focal_4.14_armhf
