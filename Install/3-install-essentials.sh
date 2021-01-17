#!/usr/bin/env bash

pacman -S awesome

pacman -S xorg xorg-drivers
pacman -S lightdm lightdm-slick-greeter
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

pacman -S xdg-user-dirs arc-icon-theme mate-polkit udiskie gvfs

pacman -S ntfs-3g unrar p7zip file-roller mlocate sshfs
# sudo sshfs user@ip:directory localdirectory
