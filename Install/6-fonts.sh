#!/usr/bin/env bash
# usage: ./**.sh username

pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra
# pacman -S ttf-merriweather ttf-merriweather-sans
pacman -S mathjax
pacman -S awesome-terminal-fonts
pacman -S nerd-fonts-complete
pacman -S ttf-wps-fonts

mkdir -p /home/$1/.local/share/fonts

ln -s /home/$1/Fonts/mono/OperatorMonoLig /home/$1/.local/share/fonts/operator-mono-lig
ln -s /home/$1/Fonts/mono/OperatorMono /home/$1/.local/share/fonts/operator-mono
ln -s /home/$1/Fonts/jacqueline /home/$1/.local/share/fonts/jacqueline
ln -s /home/$1/Fonts/avanti /home/$1/.local/share/fonts/avanti
ln -s /home/$1/Fonts/special /home/$1/.local/share/fonts/special
ln -s /home/$1/Windows/System/Windows/Fonts /home/$1/.local/share/fonts/windows

fc-cache -fv
