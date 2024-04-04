#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
    echo "Re-running script under sudo..."
    sudo --preserve-env "$0" "$@"
    exit
fi

TOP=$PWD
export MKE2FS_CONFIG="${TOP}/tools/mke2fs.conf"
if [ ! -f ${MKE2FS_CONFIG} ]; then
    echo "error: ${MKE2FS_CONFIG} not found."
    exit 1
fi
true ${MKFS:="${TOP}/tools/mke2fs"}

true ${SOC:=h3}
ARCH=arm
true ${KCFG:=sunxi_defconfig}
KIMG=arch/${ARCH}/boot/zImage
KDTB_NANOPI=arch/${ARCH}/boot/dts/sun8i-*-nanopi-*.dtb
KDTB_ZEROPI=arch/${ARCH}/boot/dts/sun8i-h3-zeropi.dtb
KOVERLAY=arch/${ARCH}/boot/dts/overlays
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
    rsync -a --no-o --no-g ${KERNEL_BUILD_DIR}/${KDTB_NANOPI} ${OUT}/boot_mnt/
    rsync -a --no-o --no-g ${KERNEL_BUILD_DIR}/${KDTB_ZEROPI} ${OUT}/boot_mnt/

    mkdir -p ${OUT}/boot_mnt/overlays
    rsync -a --no-o --no-g ${KERNEL_BUILD_DIR}/${KOVERLAY}/*.dtbo ${OUT}/boot_mnt/overlays
    rsync -a --no-o --no-g ${KERNEL_BUILD_DIR}/${KOVERLAY}/sun8i-h3-fixup* ${OUT}/boot_mnt/overlays/
    rsync -a --no-o --no-g ${KERNEL_BUILD_DIR}/${KOVERLAY}/README.sun8i-h3-overlays ${OUT}/boot_mnt/overlays/README.md

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

    # Extract rootfs from img
    simg2img ${TARGET_OS}/rootfs.img ${TARGET_OS}/r.img
    mkdir -p ${OUT}/rootfs_mnt
    mkdir -p ${OUT}/rootfs_new
    mount -t ext4 -o loop ${TARGET_OS}/r.img ${OUT}/rootfs_mnt
    if [ $? -ne 0 ]; then
        echo "failed to mount ${TARGET_OS}/r.img."
        exit 1
    fi
    rm -rf ${OUT}/rootfs_new/*
    cp -af ${OUT}/rootfs_mnt/* ${OUT}/rootfs_new/
    umount ${OUT}/rootfs_mnt
    rm -rf ${OUT}/rootfs_mnt
    rm -f ${TARGET_OS}/r.img


    ROOTFS_LIB=`readlink -f ${OUT}/rootfs_new/lib`

    # Processing rootfs_new
    # 注意这里不删除旧的文件，防止删除一些额外安装的模块
    (cd ${KMODULES_OUTDIR}/lib && {
        tar -cf - * | tar -xf - -p --same-owner --numeric-owner -C ${ROOTFS_LIB}
    })

    # 3rd drives
    if [ ! -z "$PREBUILT" ]; then
        if [ -d ${ROOTFS_LIB}/modules/4.14.111 ]; then
            (cd ${PREBUILT}/kernel-module/4.14.111/ && {
                tar -cf - * | tar -xf - -p --same-owner --numeric-owner -C ${ROOTFS_LIB}/modules/4.14.111
            })
        fi
        if [ -d ${PREBUILT}/wifi_firmware ]; then
            (cd ${PREBUILT}/wifi_firmware/ && {
                FIRMWARE_PATH=${ROOTFS_LIB}/firmware
                [ -d ${FIRMWARE_PATH} ] || mkdir ${FIRMWARE_PATH}
                tar -cf - * | tar -xf - -p --same-owner --numeric-owner -C ${FIRMWARE_PATH}
            })
        fi
	fi
    MKFS_OPTS="-E android_sparse -t ext4 -L rootfs -M /root -b 4096"
    case ${TARGET_OS} in
    friendlywrt* | buildroot*)
        # set default uid/gid to 0
        MKFS_OPTS="-0 ${MKFS_OPTS}"
        ;;
    *)
        ;;
    esac

    # Make rootfs.img
    ROOTFS_DIR=${OUT}/rootfs_new

    case ${TARGET_OS} in
    friendlywrt*)
        echo "prepare kernel modules for friendlywrt ..."
        ${TOP}/tools/prepare_friendlywrt_kernelmodules.sh ${ROOTFS_DIR}
        ;;
    *)
        ;;
    esac

    # clean device files
    (cd ${ROOTFS_DIR}/dev && find . ! -type d -exec rm {} \;)
    # calc image size
    IMG_SIZE=$(((`du -s -B64M ${ROOTFS_DIR} | cut -f1` + 3) * 1024 * 1024 * 64))
    IMG_BLK=$((${IMG_SIZE} / 4096))
    INODE_SIZE=$((`find ${ROOTFS_DIR} | wc -l` + 128))
    # make fs
    [ -f ${TARGET_OS}/rootfs.img ] && rm -f ${TARGET_OS}/rootfs.img
    ${MKFS} -N ${INODE_SIZE} ${MKFS_OPTS} -d ${ROOTFS_DIR} ${TARGET_OS}/rootfs.img ${IMG_BLK}

    if [ ${TARGET_OS} != "eflasher" ]; then
        echo "IMG_SIZE=${IMG_SIZE}" > ${OUT}/${TARGET_OS}_rootfs-img.info
        ${TOP}/tools/generate-partmap-txt.sh ${IMG_SIZE} ${TARGET_OS}
    fi
else 
    echo "not found ${TARGET_OS}/rootfs.img"
    exit 1
fi


