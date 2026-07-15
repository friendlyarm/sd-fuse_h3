#!/bin/bash
set -eu

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/h3/images
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/h3/images
fi
# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_h3
cd sd-fuse_h3
wget ${CDN_URL}/friendlycore-images.tgz
tar xzf friendlycore-images.tgz

git clone https://github.com/friendlyarm/linux -b sunxi-4.14.y --depth 1 kernel-h3

KERNEL_SRC=$PWD/kernel-h3 ./build-kernel.sh friendlycore
sudo ./mk-sd-image.sh friendlycore
