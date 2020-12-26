#!/usr/bin/env bash

mkdir -p $HOME/Windows/System $HOME/Windows/Data
echo -e "UUID=65F33762C14D581B $HOME/Windows/System ntfs-3g defaults 0 0\n" >>/etc/fstab
echo -e "UUID=2D97AD940A9AD661 $HOME/Windows/Data ntfs-3g defaults 0 0\n" >>/etc/fstab
