#!/bin/bash

TARGET_OS=$(echo ${1,,}|sed 's/\///g')
case ${TARGET_OS} in
ubuntu-noble-core | friendlycore-focal | friendlycore-jammy | debian-bookworm-core | debian-jessie | friendlycore | friendlywrt | eflasher)
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
