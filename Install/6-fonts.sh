#!/usr/bin/env bash

pacman -S ttf-merriweather ttf-merriweather-sans
pacman -S mathjax
pacman -S awesome-terminal-fonts
pacman -S nerd-fonts-complete
pacman -S ttf-wps-fonts

cd $HOME/.local/share/fonts
ln -s /home/avanti/Fonts/mono/OperatorMonoLig operator-mono-lig
ln -s /home/avanti/Fonts/merge merge
ln -s /home/avanti/Fonts/fangzheng fangzheng
ln -s /home/avanti/Windows/System/Windows/Fonts Windows

fc-cache -fv
