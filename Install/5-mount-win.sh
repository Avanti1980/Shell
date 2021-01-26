#!/usr/bin/env bash
# usage: ./**.sh username

mkdir -p /home/$1/Windows/System /home/$1/Windows/Data

UUID=$(echo $(lsblk -f | grep -n "nvme0n1p2" | sed 's/[ ][ ]*/ /g' | cut -d ' ' -f 3))
echo -e "UUID=$UUID /home/$1/Windows/System ntfs-3g defaults 0 0\n" >>/etc/fstab

UUID=$(echo $(lsblk -f | grep -n "nvme0n1p3" | sed 's/[ ][ ]*/ /g' | cut -d ' ' -f 3))
echo -e "UUID=$UUID /home/$1/Windows/Data ntfs-3g defaults 0 0\n" >>/etc/fstab
