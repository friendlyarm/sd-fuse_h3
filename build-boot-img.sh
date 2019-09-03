#!/bin/bash
set -eu

if [ $# -lt 2 ]; then
    echo "Usage: $0 <boot dir> <img filename>"
    echo "example:"
    echo "    tar xvzf NETDISK/H3/rootfs/rootfs-friendlycore-20190603.tgz"
    echo "    ./build-boot-img.sh friendlycore/boot friendlycore/boot.img"
    exit 1
fi
TOPDIR=$PWD

BOOT_DIR=$1
IMGFILE=$2

if [ ! -d ${BOOT_DIR} ]; then
    echo "path '${BOOT_DIR}' not found."
    exit 1
fi

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
 	sudo "$0" "$@"
 	exit
fi

#64M
RAW_SIZE_MB=$(( `grep "boot.img" $TOPDIR/prebuilt/partmap.template | cut -f 4 -d":" | cut -f 2 -d","`/1024/1024 ))
if [ -n "$RAW_SIZE_MB" ] && [ "$RAW_SIZE_MB" -eq "$RAW_SIZE_MB" ] 2>/dev/null; then
    echo ""
else
   echo "Error: RAW_SIZE_MB is not a number" >&2; 
   exit 1
fi

RAW_SIZE=`expr 1024 \* ${RAW_SIZE_MB}`
dd if=/dev/zero of=${IMGFILE} bs=1024 count=0 seek=${RAW_SIZE}

LOOP=`losetup -f`
losetup ${LOOP} ${IMGFILE}
mkfs.vfat $LOOP -n BOOT -I > /dev/null
partprobe ${LOOP}
TMPDIR=$(mktemp -d)
mount -t vfat ${LOOP} ${TMPDIR}
rsync -a --no-o --no-g ${BOOT_DIR}/* ${TMPDIR}/
umount ${TMPDIR}
rm -rf ${TMPDIR}
losetup -d ${LOOP}

echo "generating ${IMGFILE} done."
exit 0

