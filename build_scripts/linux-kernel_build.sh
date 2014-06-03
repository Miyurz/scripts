#!/bin/bash

source common.sh linux-kernel
get_details

echo I am in directory : $(pwd)
echo I am in branch, $(git branch)

echo "1) Build/compile the main kernel."
make

echo "2) Building the kernel modules now"
make modules

echo "3) At this point, you should see a directory named /lib/modules/'$(kernel_version)' in your system"

echo "4) Install the kernel modules"
# make modules_install

echo "5) Install the new kernel"
#make install

echo "6) make install will create the following files in /boot directory"
echo "6.1) vmlinux    - the actual kernel"
echo "6.2) System.map - The symbols exported by kernel"
echo "6.3) initrd.img - Temporary root file system used during boot process"
echo "6.4) config     - The kernel configuration file"
echo "6.5) make install will update the grub.cfg by default. So we don't manually need to edit the grub.cfg file"

echo "7) To use the new kernel that you just compiled, reboot the system..."
#reboot

echo "Since, in grub.cfg, the new kernel is added as default boot, the system will boot from the new kernel. Just in case, you have \
      problems with the new kernel, you can select the old kernel from the grub menu during boot and you can use your systems as usual."
      
echo "Once the system is up, use 'uname -r' to verify that the new version of Linux kernel is installed."


echo "Version of newly built kernel  i.e., vmlinuz/x = " $(strings vmlinux | grep "Linux version")
