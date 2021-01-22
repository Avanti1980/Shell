#!/usr/bin/env bash

# usage: ./**.sh username

pacman -S ttf-merriweather ttf-merriweather-sans
pacman -S mathjax
pacman -S awesome-terminal-fonts
pacman -S nerd-fonts-complete
pacman -S ttf-wps-fonts

ln -s /home/avanti/Fonts/mono/OperatorMonoLig /home/$1/.local/share/fonts/operator-mono-lig
ln -s /home/avanti/Fonts/merge /home/$1/.local/share/fonts/merge
ln -s /home/avanti/Fonts/fangzheng /home/$1/.local/share/fonts/fangzheng
ln -s /home/avanti/Windows/System/Windows/Fonts /home/$1/.local/share/fonts/Windows

fc-cache -fv
