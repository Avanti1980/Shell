#!/usr/bin/env bash

mkdir -p $HOME/Windows/System $HOME/Windows/Data

UUID=$(echo $(lsblk -f | grep -n "nvme0n1p2" | sed 's/[ ][ ]*/ /g' | cut -d ' ' -f 3))
echo -e "UUID=$UUID $HOME/Windows/System ntfs-3g defaults 0 0\n" >>/etc/fstab

UUID=$(echo $(lsblk -f | grep -n "nvme0n1p3" | sed 's/[ ][ ]*/ /g' | cut -d ' ' -f 3))
echo -e "UUID=$UUID $HOME/Windows/Data ntfs-3g defaults 0 0\n" >>/etc/fstab
