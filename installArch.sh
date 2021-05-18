#!/usr/bin/env bash

# curl -sL https://bit.ly/3uWggpc | bash > insatll.sh
# chmod +x install.sh
# ./install.sh

loadkeys de
lsblk

timedatectl set-ntp true

# boot-partition
parted -s /dev/sda mkpart primary fat32 1Mib 260MiB
parted -s /dev/sda set 1 boot on

# root-partition
parted -s /dev/sda mkpart primary ext4 261Mib 5381MiB

# home-partition
parted -s /dev/sda mkpart primary ext4 5381MiB 100%

# file systems
mkfs.fat -F 32 /dev/sda1 # boot
mkfs.ext4 /dev/sda2 # root
mkfs.ext4 /dev/sda3 # home

# mount root
mount /dev/sda2 /mnt

# mount home
mkdir /mnt/home
mount /dev/sda3 /mnt/home

# mount boot
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot




 
