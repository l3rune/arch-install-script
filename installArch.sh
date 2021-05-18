#!/usr/bin/env bash

# curl -sL https://bit.ly/3uWggpc | bash

loadkeys de

timedatectl set-ntp true


# Remove any older partitions
parted -s $HD rm 1 &> /dev/null
parted -s $HD rm 2 &> /dev/null
parted -s $HD rm 3 &> /dev/null
parted -s $HD rm 4 &> /dev/null

# Set the partition table to MS-DOS type 
parted -s /dev/sda mklabel gpt

# boot-partition
parted -s /dev/sda mkpart primary fat32 1Mib 260MiB 1>/dev/null
parted -s /dev/sda set 1 esp on 1>/dev/null
parted -s /dev/sda set 1 boot on 1>/dev/null


# root-partition
parted -s /dev/sda mkpart primary ext4 261Mib 5381MiB 1>/dev/null

# home-partition
parted -s /dev/sda mkpart primary ext4 5381MiB 100% 1>/dev/null

# file systems
mkfs.fat -F 32 /dev/sda1 1>/dev/null # boot
mkfs.ext4 /dev/sda2 1>/dev/null # root
mkfs.ext4 /dev/sda3 1>/dev/null # home

# mount root
mount /dev/sda2 /mnt

# mount home
mkdir /mnt/home
mount /dev/sda3 /mnt/home

# mount boot
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# pacstrap
echo "[ PACTSRAP ]"
pacstrap /mnt base base-devel vim networkmanager grub

# fstsb
genfstab -U /mnt >> /mnt/etc/fstab

# # entering installation
# arch-chroot /mnt

# # enable networkmanager
# systemctl enable NetworkManager

# # setup grub
# grub-install --target=i386-pc /dev/sda

# echo "[ DONE ]"


 
