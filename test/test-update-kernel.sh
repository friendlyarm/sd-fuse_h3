#!/bin/bash
set -eu

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/h3/images
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/h3/images
fi
KERNEL_URL=https://github.com/friendlyarm/linux
KERNEL_BRANCH=sunxi-4.14.y

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

git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel-h3

KERNEL_SRC=$PWD/kernel-h3 ./build-kernel.sh friendlycore-focal
sudo ./mk-sd-image.sh friendlycore-focal
sudo ./mk-emmc-image.sh friendlycore-focal
