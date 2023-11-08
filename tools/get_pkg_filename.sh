#!/bin/bash

TARGET_OS=${1,,}
case ${TARGET_OS} in
friendlycore-focal | friendlycore-jammy | debian-bookworm-core | debian-jessie | friendlycore | friendlywrt | eflasher)
	ROMFILE="${TARGET_OS}-images.tgz"
	;;
eflasher)
	ROMFILE="emmc-flasher-images.tgz"
	;;
*)
	ROMFILE=
	;;
esac
echo $ROMFILE
