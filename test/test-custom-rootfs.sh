#!/bin/bash
set -eu

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/h3/images
    ROOTFS_URL=http://cdn.local/friendlyelec-cdn/rootfs/h3
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/h3/images
    ROOTFS_URL=https://downloads.friendlyelec.com/rootfs/h3
fi
# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_h3
cd sd-fuse_h3
wget ${CDN_URL}/friendlycore-focal-images.tgz
tar xzf friendlycore-focal-images.tgz
wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget ${ROOTFS_URL}/rootfs-friendlycore-focal.tgz
wget ${ROOTFS_URL}/rootfs-friendlycore-focal.tgz.sha256
sha256sum -c rootfs-friendlycore-focal.tgz.sha256
tar xzf rootfs-friendlycore-focal.tgz
echo hello > friendlycore-focal/rootfs/root/welcome.txt
(cd friendlycore-focal/rootfs/root/ && {
	wget ${CDN_URL}/friendlycore-focal-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh friendlycore-focal/rootfs friendlycore-focal
sudo ./mk-sd-image.sh friendlycore-focal
sudo ./mk-emmc-image.sh friendlycore-focal
