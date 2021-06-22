#!/bin/bash

TARGET_OS=${1,,}
case ${TARGET_OS} in
friendlycore-focal_4.14_armhf | friendlycore-xenial_4.14_armhf | friendlywrt_4.14_armhf | eflasher)
	ROMFILE="${TARGET_OS}.tgz"
        ;;
*)
	ROMFILE=
esac
echo $ROMFILE
