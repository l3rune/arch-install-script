#!/usr/bin/env bash

# curl -sL https://bit.ly/3uWggpc | bash

#############################################
# config

ROOT_PASSWD=1234
HOSTN=arch
KEYBOARD_LAYOUT=de
LANGUAGE=en_US
LOCALE=Europe/Berlin
# in MB
BOOT_SIZE=260
ROOT_SIZE=25*1024
USERN=l3rune

##############################################

loadkeys $KEYBOARD_LAYOUT
timedatectl set-ntp true

echo "> partitioning"

# Remove older partitions
parted -s /dev/sda rm 1 &> /dev/null
parted -s /dev/sda rm 2 &> /dev/null
parted -s /dev/sda rm 3 &> /dev/null
parted -s /dev/sda rm 4 &> /dev/null

# Set the partition table to gpt type 
parted -s /dev/sda mklabel gpt

# boot-partition
parted -s /dev/sda mkpart primary fat32 1 $(($BOOT_SIZE+1))MiB
parted -s /dev/sda set 1 esp on

# root-partition
parted -s /dev/sda mkpart primary ext4 $(($BOOT_SIZE+1))MiB $(($BOOT_SIZE+1+$ROOT_SIZE))MiB

# home-partition
parted -s /dev/sda mkpart primary ext4 $(($BOOT_SIZE+1+$ROOT_SIZE))MiB 100% 

echo "> making filesystems"

# file systems
mkfs.fat -F 32 -n EFIBOOT /dev/sda1 # boot

mkfs.ext4 /dev/sda2 # root

mkfs.ext4 /dev/sda3 # home

echo "> mounting"

# mount root
mount /dev/sda2 /mnt

# mount home
mkdir /mnt/home
mount /dev/sda3 /mnt/home

# mount boot
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# pacstrap
echo "> PACTSRAP"
pacstrap /mnt base base-devel linux linux-firmware sudo vim networkmanager grub efibootmgr dosfstools gptfdisk

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "> entering installation"

# entering installation
arch-chroot /mnt << EOF

# enable networkmanager
systemctl enable NetworkManager > /dev/null

# setup grub
bootctl install
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck --debug
mkdir -p /boot/grub/locale
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
grub-mkconfig -o /boot/grub/grub.cfg

# root password
echo -e $ROOT_PASSWD"\n"$ROOT_PASSWD | passwd

# Sets hostname
echo $HOSTN > /etc/hostname
cp /etc/hosts /etc/hosts.bkp
sed 's/localhost$/localhost '$HOSTN'/' /etc/hosts > /tmp/hosts
mv /tmp/hosts /etc/hosts

# Configures the keyboard layout
echo 'KEYMAP='$KEYBOARD_LAYOUT > /etc/vconsole.conf
echo 'FONT=lat0-16' >> /etc/vconsole.conf
echo 'FONT_MAP=' >> /etc/vconsole.conf

# Setup locale.gen
cp /etc/locale.gen /etc/locale.gen.bkp
sed 's/^#'$LANGUAGE'/'$LANGUAGE/ /etc/locale.gen > /tmp/locale
mv /tmp/locale /etc/locale.gen
locale-gen

# Setup locale.conf
export LANG=$LANGUAGE'.utf-8'
echo 'LANG='$LANGUAGE'.utf-8' > /etc/locale.conf
echo 'LC_COLLATE=C' >> /etc/locale.conf
echo 'LC_TIME='$LANGUAGE'.utf-8' >> /etc/locale.conf

# Setup clock (date and time)
ln -s /usr/share/zoneinfo/$LOCALE /etc/localtime
echo $LOCALE > /etc/timezone
hwclock --systohc --utc

#add user
useradd -m -g wheel $USERN

#all sudo for wheel group
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

#install things
pacman -S xf86-video-amdgpu xorg xorg-server xorg-xinit

EOF

echo "> unmounting"
umount -R /mnt
reboot

# install virtualbox-guest-utils
# sudo pacman -S virtualbox-guest-utils
# sudo modprobe -a vboxguest vboxsf vboxvideo
# sudo VBoxClient-all # also add to .xinitrc
# systemctl enable vboxservice

# set resolution
# xrandr --newmode "1920x1080" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
# xrandr --addmode Virtual1 "1920x1080"
# xrandr --output Virtual1 --mode "1920x1080"

# custom shell prompt (.bashrc)
# If not running interactively, don't do anything
# [[ $- != *i* ]] && return
# alias ls='ls --color=auto'
# prompt
# GEEN="\[$(tput setaf 2)\]"
# RESET="\[$(tput sgr0)\]"
# PS1="\[\033[1;31m\][ \[\033[0m\]\W \[\033[1;31m\]] \[\033[1;32m\]$ ${RESET}"

# INSTALL BSPWM
# packages: [xorg] bspwm; sxhkd demenu nitrogen picom xfce-terminal chromium arandr
#
# mkdir .config
# mkdir .config/bspwm
# mkdir .config/sxhkd
# cp /usr/share/doc/bspwm/examples/bspwmrc .config/bspwm
# cp /usr/share/doc/bspwm/examples/sxhkdrc .config/sxhkd
# change terminal in sxhkdrc form urxvt to xfce4-terminal
# cp /etc/X11/xinitrc .xinitrc
# delete last lines in .xinitrc /up to for loop, "fi" is the last thing), enter:
# setxkbmap de &
# picom -f & # -f for fade effect
# exec bspwm
# for vm:
# edit /etc/xdg/picom.conf
# set vsync=false
# set resolution in arandr (addmode with xrandr)
# hit save icon
# chmod +x .screenlayout/set_res.sh
# add to .xinitrc (before picom); add xrandr --newmode and xrandr --addmor to set_res.sh
# cursor: add to .xinitrc (before picom) xsetroot -cursor_name left_ptr 
# download wallpaper; set with nitrogen; add nitrogen --restire & to .xinitrc(after set_res.sh)
# customize terminal