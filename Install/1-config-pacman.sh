#!/usr/bin/env bash

# uncomment Color VerbosePkgLists TotalDownload
sed -i 's/#Color/Color/g' /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/g' /etc/pacman.conf
sed -i 's/#TotalDownload/TotalDownload/g' /etc/pacman.conf

# uncomment [multilib]
no=$(cat /etc/pacman.conf | grep -n "\[multilib\]" | cut -d ':' -f 1)
sed -i "${no},+1 s/#//g" /etc/pacman.conf

# add archlinuxcn
if [ -z "$(cat /etc/pacman.conf | grep archlinuxcn)" ]; then
    echo -e "\n[archlinuxcn]" >>/etc/pacman.conf
    echo Server = http://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch >>/etc/pacman.conf
fi

# add arch4edu
if [ -z "$(cat /etc/pacman.conf | grep arch4edu)" ]; then
    echo -e "\n[arch4edu]" >>/etc/pacman.conf
    echo SigLevel = Never >>/etc/pacman.conf
    echo Server = http://mirrors.tuna.tsinghua.edu.cn/arch4edu/\$arch >>/etc/pacman.conf
fi

# update
rm -fr /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate archlinux
pacman -Sy archlinuxcn-keyring
