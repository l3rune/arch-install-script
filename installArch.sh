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
ROOT_SIZE=10*1024
USERN=l3rune
PW=1234

##############################################

loadkeys $KEYBOARD_LAYOUT
timedatectl set-ntp true

echo "> partitioning"

# Remove older partitions
parted -s /dev/sda rm 1
parted -s /dev/sda rm 2 
parted -s /dev/sda rm 3 
parted -s /dev/sda rm 4

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
passwd $USERN $PW

#all sudo for wheel group
echo "%wheel ALL(ALL) ALL" >> /etc/sudoers

EOF


echo "> unmounting"
umount -R /mnt
reboot


 
