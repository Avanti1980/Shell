#!/usr/bin/env bash

pacman -S awesome # 我喜欢平铺的awesome

pacman -S xorg xorg-drivers
pacman -S lightdm lightdm-slick-greeter # 用lightdm登录
systemctl enable lightdm

pacman -S yay pacman-contrib git

pacman -S networkmanager dnsmasq
systemctl enable NetworkManager

pacman -S openssh sshpass
systemctl enable sshd

pacman -S neofetch htop sysstat

pacman -S alsa-utils pulseaudio pulseaudio-alsa

pacman -S picom-git

pacman -S rxvt-unicode chromium visual-studio-code-bin pcmanfm rofi

pacman -S fcitx5-git fcitx5-gtk-git fcitx5-qt5-git fcitx5-chinese-addons-git fcitx5-mozc-git fcitx5-configtool

pacman -S zsh autojump thefuck oh-my-zsh-git zsh-completions zsh-autosuggestions zsh-syntax-highlighting
pacman -S zsh-theme-powerlevel10k powerline-common powerline-fonts
# chsh -s /bin/zsh

# 创建文件目录 图标主题 自动挂载移动硬盘 处理访问权限 添加回收站
pacman -S xdg-user-dirs arc-icon-theme mate-polkit udiskie gvfs

# 读写ntfs磁盘 文件压缩查找 挂载远程服务器磁盘到本地 查找文件
pacman -S ntfs-3g unrar p7zip file-roller mlocate sshfs
# 用法 sudo sshfs 用户名@ip地址:远程目录 本地目录
