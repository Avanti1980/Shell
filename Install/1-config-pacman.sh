#!/usr/bin/env bash

# 反注释掉 Color VerbosePkgLists TotalDownload
sed -i 's/#Color/Color/g' /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/g' /etc/pacman.conf
sed -i 's/#TotalDownload/TotalDownload/g' /etc/pacman.conf

# 反注释掉 [multilib]
sed -i 's/#\[multilib\]/\[multilib\]/g' /etc/pacman.conf

# 反注释掉 [multilib] 下面一行的 Include = /etc/pacman.d/mirrorlist
line_number=$(cat /etc/pacman.conf | grep -n "\[multilib\]" | sed -n '$p' | cut -d ':' -f 1)
sed -i "$((++line_number)) s/#//g" /etc/pacman.conf

# 添加非官方源 archlinuxcn
if [ -z "$(cat /etc/pacman.conf | grep archlinuxcn)" ]; then
    echo -e "\n[archlinuxcn]" >>/etc/pacman.conf
    echo Server = http://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch >>/etc/pacman.conf
fi

# 添加非官方源 arch4edu
if [ -z "$(cat /etc/pacman.conf | grep arch4edu)" ]; then
    echo -e "\n[arch4edu]" >>/etc/pacman.conf
    echo SigLevel = Never >>/etc/pacman.conf
    echo Server = http://mirrors.tuna.tsinghua.edu.cn/arch4edu/\$arch >>/etc/pacman.conf
fi

pacman -Sy archlinuxcn-keyring
