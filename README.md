# sd-fuse_h3
Create bootable SD card for FriendlyELEC series board, NanoPi NEO/NEO Air/M1M1 Plus/NEO Core/Duo2 etc..

## How to find the /dev name of my SD Card
Unplug all usb devices:
```
ls -1 /dev > ~/before.txt
```
plug it in, then
```
ls -1 /dev > ~/after.txt
diff ~/before.txt ~/after.txt
```

## Build friendlycore-xenial_4.14_armhf bootable SD card
```
git clone https://github.com/friendlyarm/sd-fuse_h3.git
cd sd-fuse_h3
sudo ./fusing.sh /dev/sdX friendlycore-xenial_4.14_armhf
```
You can build the following OS: friendlycore-xenial_4.14_armhf, friendlywrt_4.14_armhf.  

Notes:  
fusing.sh will check the local directory for a directory with the same name as OS, if it does not exist fusing.sh will go to download it from network.  
So you can download from the netdisk in advance, on netdisk, the images files are stored in a directory called images-for-eflasher, for example:
```
cd sd-fuse_h3
tar xvzf ../images-for-eflasher/friendlycore-xenial_4.14_armhf.tgz
sudo ./fusing.sh /dev/sdX friendlycore-xenial_4.14_armhf
```

## Build an sd card image
First, download and unpack:
```
git clone https://github.com/friendlyarm/sd-fuse_h3.git
cd sd-fuse_h3
wget http://112.124.9.243/dvdfiles/H3/images-for-eflasher/friendlycore-xenial_4.14_armhf.tgz
tar xvzf friendlycore-xenial_4.14_armhf.tgz
```
Now,  Change something under the friendlycore-xenial_4.14_armhf directory, 
for example, replace the file you compiled, then build friendlycore-xenial_4.14_armhf bootable SD card: 
```
sudo ./fusing.sh /dev/sdX friendlycore-xenial_4.14_armhf
```
or build an sd card image:
```
sudo ./mk-sd-image.sh friendlycore-xenial_4.14_armhf h3-sd-friendlycore.img
```
The following file will be generated:  
```
out/h3-sd-friendlycore.img
```
You can use dd to burn this file into an sd card:
```
sudo dd if=out/h3-sd-friendlycore.img bs=1M of=/dev/sdX
```

## Build an sdcard-to-emmc image (eflasher rom)
Enable exFAT file system support on Ubuntu:
```
sudo apt-get install exfat-fuse exfat-utils
```
Generate the eflasher raw image, and put friendlycore-xenial_4.14_armhf image files into eflasher:
```
git clone https://github.com/friendlyarm/sd-fuse_h3.git
cd sd-fuse_h3
wget http://112.124.9.243/dvdfiles/H3/images-for-eflasher/eflasher.tgz
tar xzf eflasher.tgz
sudo ./mk-emmc-image.sh friendlycore-xenial_4.14_armhf h3-eflasher-friendlycore.img
```
The following file will be generated:  
```
out/h3-eflasher-friendlycore.img
```
You can use dd to burn this file into an sd card:
```
sudo dd if=out/h3-eflasher-friendlycore.img bs=1M of=/dev/sdX
```

## Replace the file you compiled

### Install cross compiler and tools

Install the package:
```
apt install liblz4-tool android-tools-fsutils
```
Install Cross Compiler:
```
git clone https://github.com/friendlyarm/prebuilts.git
sudo mkdir -p /opt/FriendlyARM/toolchain
sudo tar xf prebuilts/gcc-x64/arm-cortexa9-linux-gnueabihf-4.9.3.tar.xz -C /opt/FriendlyARM/toolchain/
```

### Build U-boot and Kernel for FriendlyCore
Download image files:
```
cd sd-fuse_h3
wget http://112.124.9.243/dvdfiles/H3/images-for-eflasher/friendlycore-xenial_4.14_armhf.tgz
tar xzf friendlycore-xenial_4.14_armhf.tgz
```
Build kernel:
```
cd sd-fuse_h3
./build-kernel.sh friendlycore-xenial_4.14_armhf
```
Build uboot:
```
cd sd-fuse_h3
./build-uboot.sh friendlywrt_4.14_armhf
```

### Custom rootfs for FriendlyCore
Use FriendlyCore as an example:
```
git clone https://github.com/friendlyarm/sd-fuse_h3.git
cd sd-fuse_h3
wget http://112.124.9.243/dvdfiles/H3/images-for-eflasher/friendlycore-xenial_4.14_armhf.tgz
tar xzf friendlycore-xenial_4.14_armhf.tgz
wget http://112.124.9.243/dvdfiles/H3/images-for-eflasher/eflasher.tgz
tar xzf eflasher.tgz
```
Download rootfs package:
```
wget http://112.124.9.243/dvdfiles/H3/rootfs/rootfs_friendlycore_4.14.tgz
tar xzf rootfs_friendlycore_4.14.tgz -C friendlycore-xenial_4.14_armhf
```
Now,  change something under rootfs directory, like this:
```
echo hello > friendlycore-xenial_4.14_armhf/rootfs/root/welcome.txt  
```
Remake rootfs.img:
```
./build-rootfs-img.sh friendlycore-xenial_4.14_armhf/rootfs friendlycore-xenial_4.14_armhf
```
Make sdboot image:
```
sudo ./mk-sd-image.sh friendlycore-xenial_4.14_armhf
```
or make sd-to-emmc image (eflasher rom):
```
sudo ./mk-emmc-image.sh friendlycore-xenial_4.14_armhf
```
  
