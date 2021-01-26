#!/usr/bin/env bash
# usage: ./**.sh username

# install kernel and drivers
pacman -S linux-zen linux-zen-headers linux-firmware

# set time
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

# locale
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo LANG=zh_CN.UTF-8 >/etc/locale.conf

# hostname
echo $1-xps17 >/etc/hostname
echo 127.0.0.1 localhost >/etc/hosts
echo ::1 localhost >>/etc/hosts

# boot
pacman -S grub os-prober efibootmgr
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# root password
passwd

# add user to wheel group
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
useradd -m -g wheel $1

# user password
passwd $1
