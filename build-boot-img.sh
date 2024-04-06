#!/bin/bash
set -eu

if [ $# -lt 2 ]; then
    echo "Usage: $0 <boot dir> <img filename>"
    echo "example:"
    echo "    tar xvzf NETDISK/H3/rootfs/rootfs-friendlycore-20190603.tgz"
    echo "    ./build-boot-img.sh friendlycore/boot friendlycore/boot.img"
    exit 1
fi
TOPPATH=$PWD

BOOT_DIR=$1
IMG_FILE=$2

if [ ! -d ${BOOT_DIR} ]; then
    echo "path '${BOOT_DIR}' not found."
    exit 1
fi

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
 	sudo --preserve-env "$0" "$@"
 	exit
fi
. ${TOPPATH}/tools/util.sh
check_and_install_package

#64M
RAW_SIZE_MB=$(( `grep "boot.img" $TOPPATH/prebuilt/partmap.template | cut -f 4 -d":" | cut -f 2 -d","`/1024/1024 ))
if [ -n "$RAW_SIZE_MB" ] && [ "$RAW_SIZE_MB" -eq "$RAW_SIZE_MB" ] 2>/dev/null; then
    echo ""
else
   echo "Error: RAW_SIZE_MB is not a number" >&2; 
   exit 1
fi

RAW_SIZE=`expr 1024 \* ${RAW_SIZE_MB}`
dd if=/dev/zero of=${IMG_FILE} bs=1024 count=0 seek=${RAW_SIZE}

DEV=`losetup -f`
for i in `seq 3`; do
    if [ -b ${DEV} ]; then
        break
    else
        echo "Waitting ${DEV}"
        sleep 1
    fi
done
losetup ${DEV} ${IMG_FILE}
sleep 1
mkfs.vfat $DEV -n BOOT -I > /dev/null
partprobe ${DEV}
TMPDIR=$(mktemp -d)
mount -t vfat ${DEV} ${TMPDIR}
rsync -a --no-o --no-g ${BOOT_DIR}/* ${TMPDIR}/
umount ${TMPDIR}
rm -rf ${TMPDIR}
losetup -d ${DEV}

echo "generating ${IMG_FILE} done."
exit 0

