#!/usr/bin/env bash

# usage: ./**.sh username

pacman -S intel-ucode intel-media-driver intel-compute-runtime
pacman -S libva-vdpau-driver mesa-vdpau libvdpau-va-gl vdpauinfo
pacman -S nvidia-dkms nvidia-utils opencl-nvidia
pacman -S bumblebee primus
systemctl enable bumblebeed.service
usermod -aG bumblebee $1

pacman -S betterlockscreen
pacman -S curl wget youtube-dl transmission-qt ffsend-bin
pacman -S v2ray qv2ray-dev-git qv2ray-plugin-ssr-dev-git proxychains-ng
pacman -S geogebra
pacman -S flameshot
pacman -S deepin-image-viewer
pacman -S deepin-picker
pacman -S baidupcs-go-git baidunetdisk-bin
pacman -S electronic-wechat

pacman -S texlive-most texlive-lang
pacman -S perl-log-log4perl perl-yaml-tiny perl-file-homedir perl-unicode-linebreak

pacman -S evince pdftk

pacman -S typora pandoc pandoc-citeproc pandoc-crossref princexml

pacman -S hunspell hunspell-en_AU hunspell-en_CA hunspell-en_GB hunspell-en_US

pacman -S hugo npm

pacman -S ghostscript inkscape imagemagick krita                                    # picture
pacman -S mpv mpv-bash-completion-git vlc gpac mediainfo-gui mkvtoolnix-gui aegisub # video
pacman -S audacious mpg123 spek-git                                                 # music
pacman -S shntool mac                                                               # split cue
# shntool split -f example.cue -t %p\ %n\ %t -o flac example.ape

pacman -S jupyterlab python-sympy python-pillow
pacman -S python-scikit-learn python-numba python-cvxopt python-matplotlib
pacman -S python-tensorflow-opt-cuda python-pytorch-opt-cuda tensorboard

pacman -S octave octave-forge julia

pacman -S graphviz xdot dot2tex

pacman -S clang shfmt autopep8 yapf

pacman -S hplip hplip-plugin system-config-printer
