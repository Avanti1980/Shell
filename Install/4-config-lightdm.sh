#!/usr/bin/env bash

# usage: ./**.sh username

mkdir -p /usr/share/backgrounds

cp /home/$1/.config/awesome/themes/$2/wallpaper.jpg /usr/share/backgrounds/wallpaper.jpg

sed -i 's/greeter-session=lightdm-gtk-greeter/greeter-session=lightdm-slick-greeter/g' /etc/lightdm/lightdm.conf
echo \[Greeter\] >/etc/lightdm/slick-greeter.conf
echo background=/usr/share/backgrounds/wallpaper.jpg >>/etc/lightdm/slick-greeter.conf
echo draw-grid=false >>/etc/lightdm/slick-greeter.conf
echo enable-hidpi=on >>/etc/lightdm/slick-greeter.conf
echo xft-dpi=192.0 >>/etc/lightdm/slick-greeter.conf
