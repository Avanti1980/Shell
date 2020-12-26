#!/usr/bin/env bash

pacman -S ttf-merriweather ttf-merriweather-sans
pacman -S mathjax
pacman -S awesome-terminal-fonts
pacman -S nerd-fonts-complete
pacman -S ttf-wps-fonts

fc-cache -fv
