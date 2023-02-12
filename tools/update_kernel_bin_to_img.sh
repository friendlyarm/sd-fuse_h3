#!/bin/bash
set -eu
set -x

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
true ${MKFS:="${TOP}/tools/make_ext4fs"}
true ${MKFS:="${TOP}/tools/make_ext4fs"}

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
    MKFS_OPTS="-s -a root -L rootfs"
    if echo ${TARGET_OS} | grep friendlywrt -i >/dev/null; then
        # set default uid/gid to 0
        MKFS_OPTS="-0 ${MKFS_OPTS}"
    fi
    # Make rootfs.img
    ROOTFS_DIR=${OUT}/rootfs_new
    # calc image size
    ROOTFS_SIZE=`du -s -B 1 ${ROOTFS_DIR} | cut -f1`
    # +1024m + 10% rootfs size
    MAX_IMG_SIZE=$((${ROOTFS_SIZE} + 1024*1024*1024 + ${ROOTFS_SIZE}/10))
    TMPFILE=`tempfile`
    ${MKFS} -s -l ${MAX_IMG_SIZE} -a root -L rootfs /dev/null ${ROOTFS_DIR} > ${TMPFILE}
    IMG_SIZE=`cat ${TMPFILE} | grep "Suggest size:" | cut -f2 -d ':' | awk '{gsub(/^\s+|\s+$/, "");print}'`
    rm -f ${TMPFILE}

    if [ ${ROOTFS_SIZE} -gt ${IMG_SIZE} ]; then
            echo "IMG_SIZE less than ROOTFS_SIZE, why?"
            exit 1
    fi

    # make fs
    ${MKFS} ${MKFS_OPTS} -l ${IMG_SIZE} ${TARGET_OS}/rootfs.img ${ROOTFS_DIR}
    if [ $? -ne 0 ]; then
            echo "error: failed to make rootfs.img."
            exit 1
    fi

    if [ ${TARGET_OS} != "eflasher" ]; then
        echo "IMG_SIZE=${IMG_SIZE}" > ${OUT}/${TARGET_OS}_rootfs-img.info
        ${TOP}/tools/generate-partmap-txt.sh ${IMG_SIZE} ${TARGET_OS}
    fi
else 
	echo "not found ${TARGET_OS}/rootfs.img"
	exit 1
fi

