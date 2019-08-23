#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
        echo "Re-running script under sudo..."
        sudo "$0" "$@"
        exit
fi

true ${SOC:=h3}
ARCH=arm
KCFG=sunxi_defconfig
KIMG=arch/${ARCH}/boot/zImage
KDTB=arch/${ARCH}/boot/dts/sun8i-*-nanopi-*.dtb
KALL="zImage dtbs"
CROSS_COMPILER=arm-linux-
# ${OUT} ${KERNEL_SRC} ${TOPPATH}/${TARGET_OS} ${TOPPATH}/prebuilt
if [ $# -ne 4 ]; then
        echo "bug: missing arg, $0 needs four args"
        exit
fi
OUT=$1
KERNEL_BUILD_DIR=$2
TARGET_OS=$3
PREBUILT=$4
KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"

# copy kernel to boot.img
if [ -f ${TARGET_OS}/boot.img ]; then
    echo "copying kernel to boot.img ..."
    mkdir -p ${OUT}/boot_mnt
    mount -o loop ${TARGET_OS}/boot.img ${OUT}/boot_mnt
    RET=$?

    rsync -a --no-o --no-g ${KERNEL_BUILD_DIR}/${KIMG} ${OUT}/boot_mnt/
    rsync -a --no-o --no-g ${KERNEL_BUILD_DIR}/${KDTB} ${OUT}/boot_mnt/

    # cp ${KERNEL_BUILD_DIR}/${KIMG} ${OUT}/boot_mnt/
    # cp -avf ${KERNEL_BUILD_DIR}/${KDTB} ${OUT}/boot_mnt/

    rm -rf ${OUT}/boot
    cp -af ${OUT}/boot_mnt ${OUT}/boot

    umount ${OUT}/boot_mnt
    rm -rf ${OUT}/boot_mnt

    if [ ${RET} -ne 0 ]; then
        echo "failed to update kernel to boot.img."
        exit 1
    fi
else 
	echo "not found ${TARGET_OS}/boot.img"
	exit 1
fi

# copy kernel modules to rootfs.img
if [ -f ${TARGET_OS}/rootfs.img ]; then
    echo "copying kernel module and firmware to rootfs ..."

    simg2img ${TARGET_OS}/rootfs.img ${TARGET_OS}/r.img
    # rootfs.img mount point
    mkdir -p ${OUT}/rootfs_mnt
    mount -t ext4 -o loop ${TARGET_OS}/r.img ${OUT}/rootfs_mnt
    RET=$?
    # 注意这里不删除旧的文件，防止删除一些额外安装的模块
    cp -af ${KMODULES_OUTDIR}/* ${OUT}/rootfs_mnt/

    # 3rd drives
    if [ ! -z "$PREBUILT" ]; then
        if [ -d ${OUT}/rootfs_mnt/lib/modules/4.14.111 ]; then
            cp -af ${PREBUILT}/kernel-module/4.14.111/* ${OUT}/rootfs_mnt/lib/modules/4.14.111/
        fi
        mkdir -p ${PREBUILT}/firmware
        cp -af ${PREBUILT}/firmware/* ${OUT}/rootfs_mnt/lib/firmware/
    fi

    umount ${OUT}/rootfs_mnt
    rm -rf ${OUT}/rootfs_mnt
    img2simg ${TARGET_OS}/r.img ${TARGET_OS}/rootfs.img
    rm -f ${TARGET_OS}/r.img

    if [ ${RET} -ne 0 ]; then
        echo "failed to update kernel-modules to rootfs.img."
        exit 1
    fi
else 
	echo "not found ${TARGET_OS}/rootfs.img"
	exit 1
fi

